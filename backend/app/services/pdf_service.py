import pypdf
import os

def load_pdf_bytes(file_path: str) -> bytes:
    """Reads the PDF file and returns its content as bytes."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"PDF file not found at: {file_path}")
    
    with open(file_path, "rb") as f:
        return f.read()

def extract_pdf_text(file_path: str) -> str:
    """Extracts all text from the PDF file without chunking."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"PDF file not found at: {file_path}")
    
    text_content = []

    try:
        
        reader = pypdf.PdfReader(file_path)
        for page in reader.pages:
            text = page.extract_text()
            if text:
                text_content.append(text)
        
        # Join all pages with newlines
        return "\n".join(text_content)
    except Exception as e:
        print(f"Error extracting text: {e}")
        return ""

def load_pdf_text_from_subjects(
    subject_filenames: list[str], 
    base_dir: str
) -> str:
    """
    Given a list of filenames, loads them from `base_dir` 
    and returns combined text.
    """
    combined_text = []
    
    for filename in subject_filenames:
        path = os.path.join(base_dir, filename)
        if os.path.exists(path):
            print(f"Loading PDF: {filename}")
            text = extract_pdf_text(path)
            combined_text.append(f"--- START OF {filename} ---\n{text}\n--- END OF {filename} ---")
        else:
            print(f"Warning: PDF not found: {path}")

    return "\n\n".join(combined_text)
