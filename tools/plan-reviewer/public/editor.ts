import { EditorState, Range, StateEffect } from "@codemirror/state";
import { EditorView, keymap, Decoration, DecorationSet, ViewPlugin, ViewUpdate, hoverTooltip } from "@codemirror/view";
import { markdown } from "@codemirror/lang-markdown";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { marked } from "marked";

declare global {
  interface Window {
    __PLAN_CONTENT__: string;
    __PLAN_PATH__: string;
    __PLAN_NAME__: string;
    __PLAN_DISPLAY_PATH__: string;
    _mermaid?: {
      run: (opts: { nodes: NodeListOf<Element> }) => Promise<void>;
      initialize: (opts: object) => void;
    };
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
  } | null;
  comment: string;
}

const refreshDecorations = StateEffect.define<null>();
const setPendingSelectionEffect = StateEffect.define<{ from: number; to: number } | null>();

const pendingSelectionPlugin = ViewPlugin.fromClass(
  class {
    decorations: DecorationSet;
    constructor() { this.decorations = Decoration.none; }
    update(u: ViewUpdate) {
      for (const tr of u.transactions) {
        for (const e of tr.effects) {
          if (e.is(setPendingSelectionEffect)) {
            if (e.value && e.value.from < e.value.to) {
              this.decorations = Decoration.set([
                Decoration.mark({ class: "cm-pending-selection" }).range(e.value.from, e.value.to),
              ]);
            } else {
              this.decorations = Decoration.none;
            }
          }
        }
      }
    }
  },
  { decorations: v => v.decorations }
);

let activeTab: "editor" | "preview" = "preview";
let annotations: Annotation[] = [];
let pendingFrom = -1;
let pendingTo = -1;
let pendingText = "";
let pendingSource: "editor" | "preview" = "editor";
let editingAnnotationId: string | null = null;
let view: EditorView;
let previewShowTimer: ReturnType<typeof setTimeout> | null = null;
let previewHideTimer: ReturnType<typeof setTimeout> | null = null;
let previewTooltipEl: HTMLElement | null = null;
let editorPopoverTimer: ReturnType<typeof setTimeout> | null = null;
let isMouseDown = false;

const highContrastTheme = EditorView.theme(
  {
    "&": {
      backgroundColor: "var(--color-editor)",
      color: "var(--color-text)",
      height: "100%",
      fontSize: "var(--text-editor)",
    },
    ".cm-content": {
      fontFamily: "var(--font-mono)",
      lineHeight: "var(--leading-editor)",
      caretColor: "var(--color-accent)",
    },
    ".cm-focused": { outline: "none" },
    "&.cm-focused .cm-cursor": { borderLeftColor: "var(--color-accent)", borderLeftWidth: "var(--border-width-thick)" },
    "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection": {
      backgroundColor: "var(--color-selection)",
    },
    ".cm-gutters": {
      backgroundColor: "var(--color-editor)",
      color: "var(--color-gutter-fg)",
      borderRight: "var(--border-width) solid var(--color-gutter-border)",
    },
    ".cm-lineNumbers .cm-gutterElement": { padding: "0 var(--space-5) 0 var(--space-2)", minWidth: "36px" },
    ".cm-activeLine": { backgroundColor: "var(--color-active-line)" },
    ".cm-activeLineGutter": { backgroundColor: "var(--color-active-line)", color: "var(--color-gutter-active)" },
    ".cm-annotation-highlight": {
      backgroundColor: "var(--color-accent-highlight)",
      borderBottom: "2px solid var(--color-accent)",
      borderRadius: "var(--radius-1)",
    },
    ".cm-pending-selection": {
      backgroundColor: "var(--color-selection)",
      borderRadius: "var(--radius-1)",
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
        if (ann.from < 0) continue;
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
  const ann = annotations.find(a => a.from >= 0 && a.from <= pos && pos <= a.to);
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
  if (nameEl) nameEl.textContent = window.__PLAN_DISPLAY_PATH__ ?? window.__PLAN_NAME__ ?? "plan.md";

  const state = EditorState.create({
    doc: content,
    extensions: [
      history(),
      keymap.of([...defaultKeymap, ...historyKeymap]),
      markdown(),
      highContrastTheme,
      EditorView.lineWrapping,
      annotationDecorationsPlugin,
      pendingSelectionPlugin,
      annotationHoverTooltip,
      EditorView.updateListener.of(onEditorUpdate),
    ],
  });

  view = new EditorView({
    state,
    parent: document.getElementById("editor-container")!,
  });
}

function switchTab(tab: "editor" | "preview") {
  activeTab = tab;
  const editorEl = document.getElementById("editor-container")!;
  const previewEl = document.getElementById("preview-container")!;
  const tabEditorEl = document.getElementById("tab-editor")!;
  const tabPreviewEl = document.getElementById("tab-preview")!;

  if (tab === "editor") {
    removePreviewAnnotationTooltip();
    editorEl.classList.remove("hidden");
    previewEl.classList.add("hidden");
    tabEditorEl.classList.add("tab-active");
    tabPreviewEl.classList.remove("tab-active");
  } else {
    editorEl.classList.add("hidden");
    previewEl.classList.remove("hidden");
    tabEditorEl.classList.remove("tab-active");
    tabPreviewEl.classList.add("tab-active");
    hideInlinePopover();
    renderPreview();
  }
}

async function renderPreview() {
  removePreviewAnnotationTooltip();
  const content = view.state.doc.toString();
  const html = marked.parse(content, { gfm: true }) as string;
  const container = document.getElementById("preview-container")!;
  container.innerHTML = `<div class="preview-body">${html}</div>`;

  const codeBlocks = container.querySelectorAll("pre code.language-mermaid");
  for (const block of Array.from(codeBlocks)) {
    const pre = block.parentElement!;
    const div = document.createElement("div");
    div.className = "mermaid";
    div.textContent = block.textContent || "";
    pre.replaceWith(div);
  }

  const mermaid = window._mermaid;
  if (mermaid) {
    const nodes = container.querySelectorAll(".mermaid");
    if (nodes.length > 0) {
      try {
        await mermaid.run({ nodes });
      } catch (e) {
        console.warn("Mermaid rendering error:", e);
      }
    }
  }

  highlightAnnotationsInPreview(container);
}

function plainText(md: string): string {
  const tmp = document.createElement("div");
  tmp.innerHTML = marked.parse(md, { gfm: true }) as string;
  return (tmp.textContent || "").trim();
}

// Whitespace-normalised search: collapses any whitespace run to a single space so
// that mismatches between browser selection text and TreeWalker text don't block
// matching. Returns original (non-normalised) from/to positions in `full`.
function normFind(full: string, searchText: string): { from: number; to: number } | null {
  // Build normalised form and a map from normalised-index → original-index
  const pairs: Array<[string, number]> = [];
  let prevSpace = true; // start as if preceded by space to strip leading whitespace
  for (let i = 0; i < full.length; i++) {
    if (/\s/.test(full[i])) {
      if (!prevSpace) { pairs.push([' ', i]); prevSpace = true; }
    } else {
      pairs.push([full[i], i]);
      prevSpace = false;
    }
  }
  if (pairs.length > 0 && pairs[pairs.length - 1][0] === ' ') pairs.pop();

  const normFull   = pairs.map(p => p[0]).join('');
  const normSearch = searchText.replace(/\s+/g, ' ').trim();
  if (!normSearch) return null;

  const np = normFull.indexOf(normSearch);
  if (np < 0) return null;

  return {
    from: pairs[np][1],
    to:   pairs[np + normSearch.length - 1][1] + 1,
  };
}

function highlightAnnotationsInPreview(container: HTMLElement) {
  clearPreviewHighlights(container);

  const filter: NodeFilter = {
    acceptNode(node) {
      return (node.parentElement as Element)?.closest(".mermaid, svg")
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT;
    },
  };

  // Collect text nodes ONCE before any DOM modification
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, filter);
  const nodes: Text[] = [];
  let n: Node | null;
  while ((n = walker.nextNode())) nodes.push(n as Text);

  const lens = nodes.map(t => (t.textContent || "").length);
  const full = nodes.map(t => t.textContent || "").join("");

  // Compute highlight ranges for all annotations
  const toWrap: Array<{ from: number; to: number; annId: string }> = [];
  for (const ann of annotations) {
    if (!ann.text) continue;
    const searchText = plainText(ann.text);
    if (!searchText) continue;
    let from = full.indexOf(searchText);
    let to = from + searchText.length;
    if (from < 0) {
      // Fallback: whitespace-normalised search handles mismatches between the
      // browser's selection.toString() (one \n between blocks, space after
      // checkboxes) and our TreeWalker's concatenated text (\n\n between
      // block elements, leading space in list items, etc.).
      const nm = normFind(full, searchText);
      if (!nm) continue;
      ({ from, to } = nm);
    }
    toWrap.push({ from, to, annId: ann.id });
  }
  if (!toWrap.length) return;

  // Sort ascending, remove overlapping ranges (keep first)
  toWrap.sort((a, b) => a.from - b.from);
  const clean: typeof toWrap = [];
  let lastTo = -1;
  for (const h of toWrap) {
    if (h.from >= lastTo) { clean.push(h); lastTo = h.to; }
  }

  // Apply in REVERSE order (rightmost annotation first) so earlier text positions
  // stay valid after DOM modifications.
  for (let hi = clean.length - 1; hi >= 0; hi--) {
    const { from, to, annId } = clean[hi];
    let startIdx = -1, startOff = 0, endIdx = -1, endOff = 0, cum = 0;

    for (let i = 0; i < nodes.length; i++) {
      if (startIdx === -1 && cum + lens[i] > from) { startIdx = i; startOff = from - cum; }
      if (startIdx !== -1 && cum + lens[i] >= to)  { endIdx = i; endOff = to - cum; break; }
      cum += lens[i];
    }
    if (startIdx === -1 || endIdx === -1) continue;

    try {
      if (startIdx === endIdx) {
        // Single text node — simple inline wrap, no block-crossing issues
        wrapTextSegment(nodes[startIdx], startOff, endOff, annId);
      } else {
        // Multi-node span — wrap each text node individually (right-to-left so
        // splitText calls don't invalidate the pre-computed offsets for earlier nodes).
        wrapTextSegment(nodes[endIdx], 0, endOff, annId);
        for (let i = endIdx - 1; i > startIdx; i--) {
          wrapTextSegment(nodes[i], 0, lens[i], annId);
        }
        wrapTextSegment(nodes[startIdx], startOff, lens[startIdx], annId);
      }
    } catch { /* detached node */ }
  }
}

function wrapTextSegment(textNode: Text, from: number, to: number, annId: string) {
  if (from >= to) return;
  // Skip whitespace-only segments: inserting <mark> as a direct child of <tr>,
  // <ul>, <ol>, or <table> is invalid HTML and causes the browser to eject the
  // element from the table/list structure.
  const segment = (textNode.textContent || "").slice(from, to);
  if (!segment.trim()) return;
  const parent = textNode.parentNode!;
  let node: Text = textNode;
  if (from > 0) node = textNode.splitText(from);
  if ((to - from) < (node.textContent || "").length) node.splitText(to - from);
  const mark = document.createElement("mark");
  mark.className = "preview-ann-highlight";
  mark.dataset.id = annId;
  parent.insertBefore(mark, node);
  mark.appendChild(node);
}

function clearPreviewHighlights(container: HTMLElement) {
  for (const mark of Array.from(container.querySelectorAll(".preview-ann-highlight"))) {
    const parent = mark.parentNode!;
    while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
    parent.removeChild(mark);
    parent.normalize();
  }
}

function applyPreviewPendingHighlight() {
  if (!pendingText) return;
  const container = document.getElementById("preview-container");
  if (!container) return;
  clearPreviewPendingHighlight();

  const filter: NodeFilter = {
    acceptNode(node) {
      return (node.parentElement as Element)?.closest(".mermaid, svg")
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT;
    },
  };
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, filter);
  const nodes: Text[] = [];
  let n: Node | null;
  while ((n = walker.nextNode())) nodes.push(n as Text);

  const lens = nodes.map(t => (t.textContent || "").length);
  const full = nodes.map(t => t.textContent || "").join("");
  const searchText = plainText(pendingText);
  if (!searchText) return;

  let from = full.indexOf(searchText);
  let to = from + searchText.length;
  if (from < 0) {
    const nm = normFind(full, searchText);
    if (!nm) return;
    ({ from, to } = nm);
  }

  let startIdx = -1, startOff = 0, endIdx = -1, endOff = 0, cum = 0;
  for (let i = 0; i < nodes.length; i++) {
    if (startIdx === -1 && cum + lens[i] > from) { startIdx = i; startOff = from - cum; }
    if (startIdx !== -1 && cum + lens[i] >= to)  { endIdx = i; endOff = to - cum; break; }
    cum += lens[i];
  }
  if (startIdx === -1 || endIdx === -1) return;

  try {
    if (startIdx === endIdx) {
      wrapPendingSegment(nodes[startIdx], startOff, endOff);
    } else {
      wrapPendingSegment(nodes[endIdx], 0, endOff);
      for (let i = endIdx - 1; i > startIdx; i--) wrapPendingSegment(nodes[i], 0, lens[i]);
      wrapPendingSegment(nodes[startIdx], startOff, lens[startIdx]);
    }
  } catch { /* detached node */ }
}

function wrapPendingSegment(textNode: Text, from: number, to: number) {
  if (from >= to) return;
  const segment = (textNode.textContent || "").slice(from, to);
  if (!segment.trim()) return;
  const parent = textNode.parentNode!;
  let node: Text = textNode;
  if (from > 0) node = textNode.splitText(from);
  if ((to - from) < (node.textContent || "").length) node.splitText(to - from);
  const m = document.createElement("mark");
  m.className = "pending-selection-highlight";
  parent.insertBefore(m, node);
  m.appendChild(node);
}

function clearPreviewPendingHighlight() {
  const container = document.getElementById("preview-container");
  if (!container) return;
  for (const mark of Array.from(container.querySelectorAll(".pending-selection-highlight"))) {
    const parent = mark.parentNode!;
    while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
    parent.removeChild(mark);
    parent.normalize();
  }
}

function showPreviewAnnotationTooltip(mark: HTMLElement) {
  const id = mark.dataset.id;
  if (!id) return;
  const ann = annotations.find(a => a.id === id);
  if (!ann) return;

  removePreviewAnnotationTooltip();

  const el = document.createElement("div");
  el.className = "ann-tooltip";
  el.innerHTML = `
    <p class="ann-tooltip-comment">${escHtml(ann.comment)}</p>
    <div class="ann-tooltip-actions">
      <button class="ann-tooltip-btn ann-tooltip-edit" data-id="${id}">Edit</button>
      <button class="ann-tooltip-btn ann-tooltip-remove" data-id="${id}">Remove</button>
    </div>`;

  const rect = mark.getBoundingClientRect();
  el.style.cssText = `position:fixed;z-index:var(--z-float);left:${rect.left}px;top:${rect.top - 8}px;transform:translateY(-100%)`;

  (el.querySelector(".ann-tooltip-edit") as HTMLButtonElement).addEventListener("click", () => {
    removePreviewAnnotationTooltip();
    editAnnotation(id);
  });
  (el.querySelector(".ann-tooltip-remove") as HTMLButtonElement).addEventListener("click", () => {
    removePreviewAnnotationTooltip();
    deleteAnnotation(id);
  });
  el.addEventListener("mouseenter", () => {
    if (previewHideTimer) { clearTimeout(previewHideTimer); previewHideTimer = null; }
  });
  el.addEventListener("mouseleave", () => {
    previewHideTimer = setTimeout(removePreviewAnnotationTooltip, 150);
  });

  document.body.appendChild(el);
  previewTooltipEl = el;

  if (el.getBoundingClientRect().top < 0) {
    el.style.top = `${rect.bottom + 8}px`;
    el.style.transform = "";
  }
}

function removePreviewAnnotationTooltip() {
  if (previewShowTimer) { clearTimeout(previewShowTimer); previewShowTimer = null; }
  if (previewHideTimer) { clearTimeout(previewHideTimer); previewHideTimer = null; }
  if (previewTooltipEl) { previewTooltipEl.remove(); previewTooltipEl = null; }
}

// Maps a preview selection (browser-rendered text, no markdown formatting) back to a
// range in the raw markdown doc for the editor decoration.
//
// The browser gives e.g. "Phase 2 — Integration\n Update API gateway" while the
// markdown has "### Phase 2 — Integration\n\n- [ ] Update API gateway\n...".
// Strategy: find the first non-empty trimmed line as a substring in the doc (heading
// text, body text, and list item text all appear verbatim in the markdown), then find
// the start of that markdown line. For the last line, try progressively shorter
// prefixes to skip over inline-code backticks that the preview doesn't show.
function findEditorRange(selectedText: string, doc: string): { from: number; to: number } | null {
  const lines = selectedText.split('\n').map(l => l.trim()).filter(Boolean);
  if (!lines.length) return null;

  const firstLine = lines[0];
  const firstPos = doc.indexOf(firstLine);
  if (firstPos < 0) return null;

  // Back up to the start of the markdown line (includes ## / - [ ] / etc.)
  const from = doc.lastIndexOf('\n', firstPos - 1) + 1;

  const lastLine = lines[lines.length - 1];
  let lastPos = doc.indexOf(lastLine);
  if (lastPos < 0) {
    // Progressive prefix: shorten from the right until we find a match.
    // This handles e.g. "Update frontend TokenManager" when the doc has
    // "Update frontend `TokenManager`" — we find "Update frontend " first.
    for (let len = Math.min(lastLine.length - 1, 24); len >= 8; len--) {
      lastPos = doc.indexOf(lastLine.slice(0, len));
      if (lastPos >= 0) break;
    }
  }
  if (lastPos < 0) lastPos = firstPos;

  const lineEnd = doc.indexOf('\n', lastPos);
  const to = lineEnd >= 0 ? lineEnd : doc.length;
  return from <= to ? { from, to } : null;
}

function handlePreviewSelection() {
  const sel = window.getSelection();
  if (!sel || sel.isCollapsed) {
    hideInlinePopover();
    return;
  }
  const container = document.getElementById("preview-container")!;
  if (!sel.anchorNode || !container.contains(sel.anchorNode)) {
    hideInlinePopover();
    return;
  }
  const selectedText = sel.toString().trim();
  if (!selectedText) {
    hideInlinePopover();
    return;
  }

  pendingText = selectedText;
  pendingSource = "preview";

  const editorRange = findEditorRange(selectedText, view.state.doc.toString());
  pendingFrom = editorRange?.from ?? -1;
  pendingTo = editorRange?.to ?? -1;

  const range = sel.getRangeAt(0);
  const rect = range.getBoundingClientRect();
  showInlinePopover(rect.left, rect.bottom);
}

function onEditorUpdate(update: ViewUpdate) {
  if (!update.selectionSet) return;
  if (activeTab !== "editor") return;

  const sel = update.view.state.selection.main;
  if (sel.empty) {
    if (editorPopoverTimer) { clearTimeout(editorPopoverTimer); editorPopoverTimer = null; }
    hideInlinePopover();
    return;
  }

  pendingFrom = sel.from;
  pendingTo = sel.to;
  pendingText = update.view.state.sliceDoc(sel.from, sel.to);

  // Only show the popover after the mouse is released (selection finalized).
  // Keyboard selections (isMouseDown = false) show immediately.
  if (!isMouseDown) {
    if (editorPopoverTimer) { clearTimeout(editorPopoverTimer); editorPopoverTimer = null; }
    const coords = update.view.coordsAtPos(sel.to);
    if (coords) showInlinePopover(coords.left, coords.bottom);
  }
}

function showInlinePopover(viewportLeft: number, viewportBottom: number) {
  // Apply fake selection highlight synchronously, before textarea.focus() steals it
  if (activeTab === "editor" && pendingFrom >= 0 && pendingTo > pendingFrom) {
    view.dispatch({ effects: setPendingSelectionEffect.of({ from: pendingFrom, to: pendingTo }) });
  } else if (activeTab === "preview") {
    applyPreviewPendingHighlight();
  }

  const popover = document.getElementById("inline-popover")!;
  const input = document.getElementById("inline-comment-input") as HTMLTextAreaElement;
  input.value = "";
  popover.classList.remove("hidden");

  let left = viewportLeft;
  let top = viewportBottom + 8;

  const pw = popover.offsetWidth || 260;
  if (left + pw > window.innerWidth - 8) left = window.innerWidth - pw - 8;
  if (left < 8) left = 8;
  const ph = popover.offsetHeight || 112;
  if (top + ph > window.innerHeight - 8) top = viewportBottom - ph - 8;

  popover.style.left = `${left}px`;
  popover.style.top = `${top}px`;

  setTimeout(() => input.focus(), 0);
}

function hideInlinePopover() {
  document.getElementById("inline-popover")!.classList.add("hidden");
  view.dispatch({ effects: setPendingSelectionEffect.of(null) });
  clearPreviewPendingHighlight();
}

function saveInlineComment() {
  const input = document.getElementById("inline-comment-input") as HTMLTextAreaElement;
  const comment = input.value.trim();
  if (!comment) { hideInlinePopover(); return; }

  if (pendingSource === "editor" && (pendingFrom === -1 || pendingFrom >= pendingTo)) {
    hideInlinePopover();
    return;
  }
  if (pendingSource === "preview" && !pendingText) {
    hideInlinePopover();
    return;
  }

  let range: Annotation["range"] = null;
  if (pendingFrom >= 0 && pendingTo > pendingFrom) {
    const state = view.state;
    const lineStart = state.doc.lineAt(pendingFrom);
    const lineEnd = state.doc.lineAt(pendingTo);
    range = {
      from: { line: lineStart.number, col: pendingFrom - lineStart.from },
      to: { line: lineEnd.number, col: pendingTo - lineEnd.from },
    };
  }

  annotations.push({
    id: crypto.randomUUID(),
    text: pendingText,
    from: pendingFrom,
    to: pendingTo,
    range,
    comment,
  });

  pendingFrom = -1;
  pendingTo = -1;
  pendingText = "";
  pendingSource = "editor";

  view.dispatch({ effects: refreshDecorations.of(null) });
  hideInlinePopover();
  renderAnnotations();
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
    let range: Annotation["range"] = null;
    if (pendingFrom >= 0 && pendingTo > pendingFrom) {
      const state = view.state;
      const lineStart = state.doc.lineAt(pendingFrom);
      const lineEnd = state.doc.lineAt(pendingTo);
      range = {
        from: { line: lineStart.number, col: pendingFrom - lineStart.from },
        to: { line: lineEnd.number, col: pendingTo - lineEnd.from },
      };
    }
    annotations.push({
      id: crypto.randomUUID(),
      text: pendingText,
      from: pendingFrom,
      to: pendingTo,
      range,
      comment,
    });
  }

  pendingFrom = -1;
  pendingTo = -1;
  pendingText = "";
  pendingSource = "editor";

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
    list.innerHTML = `<div class="empty-state"><span>No annotations yet.</span><span>Select text to annotate.</span></div>`;
  } else {
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

  if (activeTab === "preview") {
    highlightAnnotationsInPreview(document.getElementById("preview-container")!);
  }
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
(window as Record<string, unknown>).__saveInlineComment = saveInlineComment;
(window as Record<string, unknown>).__hideInlinePopover = hideInlinePopover;
(window as Record<string, unknown>).__saveAnnotation = saveAnnotation;
(window as Record<string, unknown>).__cancelAnnotation = cancelAnnotation;
(window as Record<string, unknown>).__submitReview = submitReview;
(window as Record<string, unknown>).__switchTab = switchTab;

document.addEventListener("DOMContentLoaded", () => {
  initEditor();
  renderAnnotations();
  renderPreview();
  setInterval(() => fetch("/api/heartbeat").catch(() => {}), 5_000);

  const inlineInput = document.getElementById("inline-comment-input") as HTMLTextAreaElement;
  inlineInput.addEventListener("keydown", (e) => {
    if (e.key === "Escape") { hideInlinePopover(); }
    if (e.key === "Enter" && e.metaKey) { e.preventDefault(); saveInlineComment(); }
  });

  document.addEventListener("mousedown", (e) => {
    isMouseDown = true;
    const popover = document.getElementById("inline-popover")!;
    if (!popover.classList.contains("hidden") && !popover.contains(e.target as Node)) {
      hideInlinePopover();
    }
  });

  const previewContainerEl = document.getElementById("preview-container")!;
  const editorContainerEl = document.getElementById("editor-container")!;
  document.addEventListener("mouseup", (e) => {
    isMouseDown = false;
    const popover = document.getElementById("inline-popover")!;
    if (!popover.classList.contains("hidden")) return; // popover already open — don't reset it
    if (activeTab === "preview") {
      setTimeout(handlePreviewSelection, 0);
    } else if (activeTab === "editor" && editorContainerEl.contains(e.target as Node)) {
      const sel = view.state.selection.main;
      if (!sel.empty) {
        if (editorPopoverTimer) { clearTimeout(editorPopoverTimer); editorPopoverTimer = null; }
        const coords = view.coordsAtPos(sel.to);
        if (coords) showInlinePopover(coords.left, coords.bottom);
      }
    }
  });
  previewContainerEl.addEventListener("mouseover", (e) => {
    const mark = (e.target as Element).closest(".preview-ann-highlight") as HTMLElement | null;
    if (!mark) return;
    if (previewShowTimer) { clearTimeout(previewShowTimer); previewShowTimer = null; }
    if (previewHideTimer) { clearTimeout(previewHideTimer); previewHideTimer = null; }
    previewShowTimer = setTimeout(() => showPreviewAnnotationTooltip(mark), 300);
  });
  previewContainerEl.addEventListener("mouseout", (e) => {
    const mark = (e.target as Element).closest(".preview-ann-highlight");
    const rel = (e.relatedTarget as Element)?.closest(".preview-ann-highlight");
    if (mark && mark !== rel) {
      if (previewShowTimer) { clearTimeout(previewShowTimer); previewShowTimer = null; }
      previewHideTimer = setTimeout(removePreviewAnnotationTooltip, 150);
    }
  });
});
