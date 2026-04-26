#!/usr/bin/env python3
"""Meeting notes query tool for ChromaDB.

Invoked by the meeting-search skill:
  .venv/bin/python tools/query.py "<question or hypothetical excerpt>" [--n 5]

Output: raw context blocks to stdout — [[Source](url)]\n<document> separated by \n---\n
"""

import argparse
import os
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", module="urllib3")

_SKILL_DIR = Path(__file__).parent.parent
_ENV_PATH = _SKILL_DIR / ".env"

COLLECTION_NAME = "qaa"
DEFAULT_DATA_SOURCE = "meetings"
DEFAULT_MODEL = "BAAI/bge-small-en-v1.5"
DEFAULT_N_RESULTS = 5


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
            texts,
            normalize_embeddings=True,
            batch_size=32,
            show_progress_bar=False,
        )
        return result if isinstance(result, np.ndarray) else np.array(result)

    def __call__(self, input):  # noqa: A002
        return self._encode(input)

    def embed_documents(self, input):  # noqa: A002
        return self._encode(input)

    def embed_query(self, input):  # noqa: A002
        return self._encode(input)


def _get_client():
    import chromadb
    host = os.getenv("CHROMA_HOST", "localhost")
    port = int(os.getenv("CHROMA_PORT", "8000"))
    return chromadb.HttpClient(host=host, port=port)


def query(
    query_text: str,
    n: int = DEFAULT_N_RESULTS,
    collection_name: str = COLLECTION_NAME,
    model: str = DEFAULT_MODEL,
) -> None:
    embedding_fn = LocalEmbeddingFunction(model)
    client = _get_client()
    collection = client.get_or_create_collection(
        name=collection_name,
        embedding_function=embedding_fn,
        metadata={"hnsw:space": "cosine"},
    )

    results = collection.query(
        query_texts=[query_text],
        n_results=n,
        where={"data_source": DEFAULT_DATA_SOURCE},
    )

    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]

    if not documents:
        print("No results found.")
        return

    blocks: list[str] = []
    for doc, meta in zip(documents, metadatas):
        address = meta.get("address", "")
        date = meta.get("date", "")
        header = f"{date} · [{address}]({address})" if date else f"[Source]({address})"
        blocks.append(f"{header}\n{doc}")

    print("\n---\n".join(blocks))


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Meeting notes query tool — searches ChromaDB with HyDE excerpts"
    )
    parser.add_argument("query_text", help="Hypothetical excerpt or search phrase")
    parser.add_argument(
        "--n",
        type=int,
        default=DEFAULT_N_RESULTS,
        help=f"Number of results (default: {DEFAULT_N_RESULTS})",
    )
    parser.add_argument(
        "--collection",
        dest="collection_name",
        default=COLLECTION_NAME,
        help=f"ChromaDB collection (default: {COLLECTION_NAME})",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"SentenceTransformer model (default: {DEFAULT_MODEL})",
    )
    return parser


if __name__ == "__main__":
    _load_env()
    args = _build_parser().parse_args()
    query(
        query_text=args.query_text,
        n=args.n,
        collection_name=args.collection_name,
        model=args.model,
    )
