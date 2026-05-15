import { EditorState, Range, StateEffect } from "@codemirror/state";
import { EditorView, keymap, Decoration, DecorationSet, ViewPlugin, ViewUpdate, hoverTooltip } from "@codemirror/view";
import { markdown } from "@codemirror/lang-markdown";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";

declare global {
  interface Window {
    __PLAN_CONTENT__: string;
    __PLAN_PATH__: string;
    __PLAN_NAME__: string;
  }
}

interface Annotation {
  id: string;
  text: string;
  from: number;
  to: number;
  range: {
    from: { line: number; col: number };
    to: { line: number; col: number };
  };
  comment: string;
}

const refreshDecorations = StateEffect.define<null>();

let annotations: Annotation[] = [];
let pendingFrom = -1;
let pendingTo = -1;
let pendingText = "";
let editingAnnotationId: string | null = null;
let view: EditorView;

const highContrastTheme = EditorView.theme(
  {
    "&": {
      backgroundColor: "#121212",
      color: "#e2e2e2",
      height: "100%",
      fontSize: "14px",
    },
    ".cm-content": {
      fontFamily: "'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace",
      lineHeight: "1.8",
      caretColor: "#e8956d",
    },
    ".cm-focused": { outline: "none" },
    "&.cm-focused .cm-cursor": { borderLeftColor: "#e8956d", borderLeftWidth: "2px" },
    "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection": {
      backgroundColor: "rgba(232,149,109,0.15)",
    },
    ".cm-gutters": {
      backgroundColor: "#121212",
      color: "#444444",
      borderRight: "1px solid #222222",
    },
    ".cm-lineNumbers .cm-gutterElement": { padding: "0 10px 0 4px", minWidth: "36px" },
    ".cm-activeLine": { backgroundColor: "rgba(255,255,255,0.03)" },
    ".cm-activeLineGutter": { backgroundColor: "rgba(255,255,255,0.03)", color: "#666666" },
    ".cm-annotation-highlight": {
      backgroundColor: "rgba(232,149,109,0.18)",
      borderBottom: "2px solid #e8956d",
      borderRadius: "2px",
    },
  },
  { dark: true }
);

const annotationDecorationsPlugin = ViewPlugin.fromClass(
  class {
    decorations: DecorationSet;

    constructor(v: EditorView) {
      this.decorations = this.buildDecorations(v);
    }

    update(u: ViewUpdate) {
      const needsRefresh = u.docChanged
        || u.viewportChanged
        || u.transactions.some(t => t.effects.some(e => e.is(refreshDecorations)));
      if (needsRefresh) {
        this.decorations = this.buildDecorations(u.view);
      }
    }

    buildDecorations(v: EditorView): DecorationSet {
      const ranges: Range<Decoration>[] = [];
      const docLen = v.state.doc.length;
      const mark = Decoration.mark({ class: "cm-annotation-highlight" });
      for (const ann of annotations) {
        const from = Math.min(ann.from, docLen);
        const to = Math.min(ann.to, docLen);
        if (from < to) {
          ranges.push(mark.range(from, to));
        }
      }
      ranges.sort((a, b) => a.from - b.from);
      return Decoration.set(ranges);
    }
  },
  { decorations: (v) => v.decorations }
);

const annotationHoverTooltip = hoverTooltip((_, pos) => {
  const ann = annotations.find(a => a.from <= pos && pos <= a.to);
  if (!ann) return null;
  return {
    pos: ann.from,
    end: ann.to,
    above: true,
    create() {
      const dom = document.createElement("div");
      dom.className = "ann-tooltip";
      dom.innerHTML = `
        <p class="ann-tooltip-comment">${escHtml(ann.comment)}</p>
        <div class="ann-tooltip-actions">
          <button class="ann-tooltip-btn ann-tooltip-edit" data-id="${ann.id}">Edit</button>
          <button class="ann-tooltip-btn ann-tooltip-remove" data-id="${ann.id}">Remove</button>
        </div>`;
      dom.querySelector(".ann-tooltip-edit")!.addEventListener("click", () => editAnnotation(ann.id));
      dom.querySelector(".ann-tooltip-remove")!.addEventListener("click", () => deleteAnnotation(ann.id));
      return { dom };
    },
  };
}, { hoverTime: 300 });

function initEditor() {
  const content = window.__PLAN_CONTENT__ ?? "";

  const nameEl = document.getElementById("plan-name");
  if (nameEl) nameEl.textContent = window.__PLAN_NAME__ ?? "plan.md";

  const state = EditorState.create({
    doc: content,
    extensions: [
      history(),
      keymap.of([...defaultKeymap, ...historyKeymap]),
      markdown(),
      highContrastTheme,
      EditorView.lineWrapping,
      annotationDecorationsPlugin,
      annotationHoverTooltip,
      EditorView.updateListener.of(onEditorUpdate),
    ],
  });

  view = new EditorView({
    state,
    parent: document.getElementById("editor-container")!,
  });
}

function onEditorUpdate(update: ViewUpdate) {
  if (!update.selectionSet) return;

  const sel = update.view.state.selection.main;
  if (sel.empty) {
    hideAddCommentBtn();
    return;
  }

  pendingFrom = sel.from;
  pendingTo = sel.to;
  pendingText = update.view.state.sliceDoc(sel.from, sel.to);

  const coords = update.view.coordsAtPos(sel.from);
  if (coords) {
    showAddCommentBtn(coords.top + window.scrollY, coords.left);
  }
}

function showAddCommentBtn(top: number, left: number) {
  const btn = document.getElementById("add-comment-btn")!;
  btn.style.top = `${Math.max(0, top - 36)}px`;
  btn.style.left = `${left}px`;
  btn.classList.remove("hidden");
}

function hideAddCommentBtn() {
  document.getElementById("add-comment-btn")!.classList.add("hidden");
}

function addAnnotation() {
  hideAddCommentBtn();
  if (pendingFrom === -1 || pendingFrom >= pendingTo) return;

  const preview = document.getElementById("dialog-preview")!;
  const truncated = pendingText.length > 80 ? pendingText.slice(0, 80) + "…" : pendingText;
  preview.textContent = `"${truncated}"`;

  const input = document.getElementById("comment-input") as HTMLTextAreaElement;
  input.value = "";

  document.getElementById("comment-dialog")!.classList.remove("hidden");
  setTimeout(() => input.focus(), 50);
}

function saveAnnotation() {
  const input = document.getElementById("comment-input") as HTMLTextAreaElement;
  const comment = input.value.trim();
  if (!comment) return;

  if (editingAnnotationId) {
    // Update existing annotation
    annotations = annotations.map(a =>
      a.id === editingAnnotationId ? { ...a, comment } : a
    );
    editingAnnotationId = null;
  } else {
    // Create new annotation
    const state = view.state;
    const lineStart = state.doc.lineAt(pendingFrom);
    const lineEnd = state.doc.lineAt(pendingTo);
    annotations.push({
      id: crypto.randomUUID(),
      text: pendingText,
      from: pendingFrom,
      to: pendingTo,
      range: {
        from: { line: lineStart.number, col: pendingFrom - lineStart.from },
        to: { line: lineEnd.number, col: pendingTo - lineEnd.from },
      },
      comment,
    });
  }

  pendingFrom = -1;
  pendingTo = -1;
  pendingText = "";

  view.dispatch({ effects: refreshDecorations.of(null) });
  cancelAnnotation();
  renderAnnotations();
}

function cancelAnnotation() {
  editingAnnotationId = null;
  document.getElementById("comment-dialog")!.classList.add("hidden");
}

function deleteAnnotation(id: string) {
  annotations = annotations.filter((a) => a.id !== id);
  view.dispatch({ effects: refreshDecorations.of(null) });
  renderAnnotations();
}

function editAnnotation(id: string) {
  const ann = annotations.find(a => a.id === id);
  if (!ann) return;

  editingAnnotationId = id;
  pendingFrom = ann.from;
  pendingTo = ann.to;
  pendingText = ann.text;

  const preview = document.getElementById("dialog-preview")!;
  const truncated = ann.text.length > 80 ? ann.text.slice(0, 80) + "…" : ann.text;
  preview.textContent = `"${truncated}"`;

  const input = document.getElementById("comment-input") as HTMLTextAreaElement;
  input.value = ann.comment;

  document.getElementById("comment-dialog")!.classList.remove("hidden");
  setTimeout(() => { input.focus(); input.select(); }, 50);
}

function renderAnnotations() {
  const list = document.getElementById("annotation-list")!;
  const count = document.getElementById("annotation-count")!;
  count.textContent = String(annotations.length);

  if (annotations.length === 0) {
    list.innerHTML = `<p class="empty-state">No annotations yet.<br>Select text and click <strong style="color:var(--sb-accent)">＋ Add comment</strong>.</p>`;
    return;
  }

  list.innerHTML = annotations
    .map(
      (ann) => `
      <div class="annotation-item" data-id="${ann.id}">
        <blockquote class="ann-quote">${escHtml(ann.text.length > 60 ? ann.text.slice(0, 60) + "…" : ann.text)}</blockquote>
        <p class="ann-comment">${escHtml(ann.comment)}</p>
        <button class="ann-delete" onclick="window.__deleteAnnotation('${ann.id}')">✕</button>
      </div>`
    )
    .join("");
}

function escHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function submitReview(action: "approve" | "request_changes" | "comment") {
  const summary = (document.getElementById("summary-input") as HTMLTextAreaElement).value.trim();
  const modifiedPlan = view.state.doc.toString();

  const payload = {
    action,
    annotations: annotations.map(({ id: _id, from: _from, to: _to, ...rest }) => rest),
    modifiedPlan,
    ...(summary ? { summary } : {}),
  };

  try {
    await fetch("/api/submit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    document.body.innerHTML = `
      <div class="done-screen">
        <p>Review submitted: <strong>${action.replace(/_/g, " ")}</strong></p>
        <p class="done-sub">Closing in 1 second…</p>
      </div>`;
    setTimeout(() => window.close(), 1000);
  } catch {
    alert("Failed to submit review. Is the plan-reviewer server still running?");
  }
}

// Expose to DOM event handlers
(window as Record<string, unknown>).__deleteAnnotation = deleteAnnotation;
(window as Record<string, unknown>).__editAnnotation = editAnnotation;
(window as Record<string, unknown>).__addAnnotation = addAnnotation;
(window as Record<string, unknown>).__saveAnnotation = saveAnnotation;
(window as Record<string, unknown>).__cancelAnnotation = cancelAnnotation;
(window as Record<string, unknown>).__submitReview = submitReview;

document.addEventListener("DOMContentLoaded", () => {
  initEditor();
  renderAnnotations();
});
