#!/usr/bin/env python3
"""
Ingest a meeting note (.md) into ChromaDB for semantic search.

Uses the same collection and embedding model as the qaa-parallel-search-skill
so that query.py can search meetings with --source meetings.

Usage: python ingest_meeting.py <path_to_meeting.md>
"""

import hashlib
import os
import re
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", module="urllib3")

_SCRIPTS_DIR = Path(__file__).parent
_ENV_PATH = _SCRIPTS_DIR / ".env"

COLLECTION_NAME = "qaa"
DEFAULT_MODEL = "BAAI/bge-small-en-v1.5"
DATA_SOURCE = "meetings"


def _load_env() -> None:
    if not _ENV_PATH.exists():
        return
    try:
        from dotenv import load_dotenv
        load_dotenv(_ENV_PATH)
    except ImportError:
        with open(_ENV_PATH, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())


class LocalEmbeddingFunction:
    def __init__(self, model_name: str = DEFAULT_MODEL) -> None:
        from sentence_transformers import SentenceTransformer
        self._model = SentenceTransformer(model_name)

    def name(self) -> str:
        return "LocalEmbeddingFunction"

    def _encode(self, input):  # noqa: A002
        import numpy as np
        texts = [input] if isinstance(input, str) else input
        result = self._model.encode(
            texts, normalize_embeddings=True, batch_size=32, show_progress_bar=False
        )
        return result if isinstance(result, np.ndarray) else np.array(result)

    def __call__(self, input):  # noqa: A002
        return self._encode(input)

    def embed_documents(self, input):  # noqa: A002
        return self._encode(input)

    def embed_query(self, input):  # noqa: A002
        return self._encode(input)


def _date_from_stem(stem: str) -> str | None:
    """Extract YYYY-MM-DD from a filename stem like '2026-04-26' or '2026-04-26_1'."""
    m = re.match(r"(\d{4}-\d{2}-\d{2})", stem)
    return m.group(1) if m else None


def ingest(file_path: Path, date: str | None = None) -> None:
    import chromadb

    content = file_path.read_text(encoding="utf-8")
    if not content.strip():
        print(f"Skipped (empty): {file_path.name}")
        return

    iso_date = date or _date_from_stem(file_path.stem)
    md5 = hashlib.md5(content.encode()).hexdigest()
    doc_id = f"meetings_{file_path.stem}"

    host = os.getenv("CHROMA_HOST", "localhost")
    port = int(os.getenv("CHROMA_PORT", "8000"))
    client = chromadb.HttpClient(host=host, port=port)

    embedding_fn = LocalEmbeddingFunction()
    collection = client.get_or_create_collection(
        name=COLLECTION_NAME,
        embedding_function=embedding_fn,
        metadata={"hnsw:space": "cosine"},
    )

    existing = collection.get(ids=[doc_id], include=["metadatas"])
    if existing["ids"] and existing["metadatas"][0].get("md5") == md5:
        print(f"Skipped (unchanged): {file_path.name}")
        return

    metadata = {
        "data_source": DATA_SOURCE,
        "address": file_path.as_uri(),
        "title": file_path.stem,
        "md5": md5,
    }
    if iso_date:
        metadata["date"] = iso_date

    collection.upsert(
        ids=[doc_id],
        documents=[content],
        metadatas=[metadata],
    )
    print(f"Ingested: {file_path.name} → collection={COLLECTION_NAME} id={doc_id}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <meeting.md>")
        sys.exit(1)

    _load_env()
    path = Path(sys.argv[1])
    if not path.exists():
        print(f"Error: {path} not found", file=sys.stderr)
        sys.exit(1)

    ingest(path)
