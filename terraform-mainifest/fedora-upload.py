#!/usr/bin/env python3
"""
Fedora Commons File Upload Script
Uploads files to Fedora Commons repository and returns the Fedora URI
"""

import os
import sys
import requests
import uuid
from urllib.parse import urljoin

# Fedora configuration
FEDORA_BASE_URL = "http://172.17.0.1:8086/fcrepo/rest"

def upload_file_to_fedora(file_path):
    """
    Upload a file to Fedora Commons repository
    
    Args:
        file_path (str): Path to the file to upload
        
    Returns:
        tuple: (success: bool, fedora_uri: str, error_message: str)
    """
    try:
        # Check if file exists
        if not os.path.exists(file_path):
            return False, "", f"❌ File not found: {file_path}"
        
        # Get file name and extension
        file_name = os.path.basename(file_path)
        file_ext = os.path.splitext(file_name)[1]
        
        # Generate a unique identifier for the Fedora object
        object_id = str(uuid.uuid4())
        
        # Create the Fedora URI
        fedora_uri = f"{FEDORA_BASE_URL}/{object_id}"
        
        # Read the file
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        # Prepare headers for binary upload
        headers = {
            'Content-Type': 'application/octet-stream',
            'Link': '<http://www.w3.org/ns/ldp#NonRDFSource>; rel="type"',
            'Slug': file_name
        }
        
        # Upload the file to Fedora
        auth = ('fedoraAdmin', 'fedoraAdmin')
        response = requests.put(
            fedora_uri,
            data=file_content,
            headers=headers,
            auth=auth,
            timeout=30
        )
        
        if response.status_code in [201, 204]:
            print(f"✅ File uploaded successfully!")
            print(f"🔗 Fedora URI: {fedora_uri}")
            return True, fedora_uri, ""
        else:
            error_msg = f"❌ Upload failed with status {response.status_code}: {response.text}"
            return False, "", error_msg
            
    except requests.exceptions.ConnectionError:
        error_msg = f"❌ Fedora connection error: {sys.exc_info()[1]}"
        error_msg += f"\n❌ Cannot connect to Fedora. Please check if Fedora is running."
        return False, "", error_msg
    except Exception as e:
        error_msg = f"❌ Error uploading file: {str(e)}"
        return False, "", error_msg

def main():
    """Main function"""
    if len(sys.argv) != 2:
        print("❌ Usage: python3 fedora-upload.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    success, fedora_uri, error = upload_file_to_fedora(file_path)
    
    if success:
        print(f"✅ File uploaded successfully!")
        print(f"🔗 Fedora URI: {fedora_uri}")
        sys.exit(0)
    else:
        print(error)
        sys.exit(1)

if __name__ == "__main__":
    main() 