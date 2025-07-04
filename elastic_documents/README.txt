Elasticsearch Documents Folder
==============================

This folder is monitored by FSCrawler for automatic document indexing.

Instructions:
- Add any documents (PDF, DOC, TXT, etc.) to this folder
- FSCrawler will automatically detect and index them within 15 minutes
- Removing files from this folder will also remove them from Elasticsearch
- Documents are indexed into the 'idx' index (not documents)

For semantic search, use the documents index via API calls.

Path mapping:
- Host: ./elastic_documents/
- Container: /tmp/es (read-only)

Supported file types: PDF, DOC, DOCX, TXT, HTML, RTF, ODT, and more.
OCR is enabled for image-based PDFs and scanned documents.

Note: This folder is ignored by git to avoid committing documents.