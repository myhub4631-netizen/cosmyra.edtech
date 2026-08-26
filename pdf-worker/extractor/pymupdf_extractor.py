import fitz  # PyMuPDF
import re

class PyMuPDFExtractor:
    @staticmethod
    def inspect_pdf(pdf_bytes: bytes):
        """Extract metadata and text stream page by page using PyMuPDF."""
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        page_count = len(doc)
        pages_data = []

        total_text_length = 0
        for page_num in range(page_count):
            page = doc[page_num]
            text = page.get_text("text")
            total_text_length += len(text)

            pages_data.append({
                "page_number": page_num + 1,
                "raw_text": text,
                "text_length": len(text),
                "has_text": len(text.strip()) > 0
            })

        return {
            "total_pages": page_count,
            "total_text_length": total_text_length,
            "pages": pages_data
        }

    @staticmethod
    def extract_full_text(pdf_bytes: bytes) -> str:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        full_text = []
        for page in doc:
            full_text.append(page.get_text("text"))
        return "\n".join(full_text)
