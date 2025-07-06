# Digital Asset Management in ArchivesSpace with Fedora

## Current Setup

✅ **ArchivesSpace Staff Interface:** http://172.173.163.116/staff/  
✅ **Fedora Repository:** http://172.173.163.116:8086/fcrepo/rest  
✅ **ActiveMQ Admin:** http://172.173.163.116:8161/admin (admin/admin)

## How to Use Digital Assets in ArchivesSpace

### 1. **Access ArchivesSpace Staff Interface**

1. Open your browser and go to: http://172.173.163.116/staff/
2. Log in with the default credentials:
   - **Username:** admin
   - **Password:** admin

### 2. **Create Digital Objects**

#### Method 1: Through the Web Interface

1. **Navigate to Digital Objects:**

   - Click on "Digital Objects" in the main menu
   - Click "Create Digital Object"

2. **Fill in Digital Object Details:**

   - **Title:** Enter a descriptive title
   - **Digital Object ID:** Unique identifier
   - **File Version:** Upload or link to digital files
   - **File Format:** Select appropriate format (PDF, JPG, etc.)
   - **Use Statement:** Rights and usage information

3. **Link to Archival Records:**
   - After creating the digital object, you can link it to:
     - Accessions
     - Resources (Finding Aids)
     - Archival Objects

#### Method 2: Through the API

```bash
# Create a digital object via API
curl -X POST \
  http://172.173.163.116:8089/repositories/2/digital_objects \
  -H "Content-Type: application/json" \
  -H "X-ArchivesSpace-Session: YOUR_SESSION_TOKEN" \
  -d '{
    "jsonmodel_type": "digital_object",
    "title": "Sample Digital Object",
    "digital_object_id": "DO_001",
    "file_versions": [
      {
        "file_uri": "http://example.com/sample.pdf",
        "file_format_name": "pdf",
        "use_statement": "image-service"
      }
    ]
  }'
```

### 3. **Link Digital Objects to Archival Records**

1. **From an Accession:**

   - Go to Accessions → Select an accession
   - Click "Add Digital Object" button
   - Select existing digital object or create new one

2. **From a Resource (Finding Aid):**

   - Go to Resources → Select a resource
   - Navigate to specific archival object
   - Click "Add Digital Object" button

3. **From an Archival Object:**
   - Go to Resources → Select resource → Select archival object
   - Click "Add Digital Object" button

### 4. **View Digital Objects**

#### In Staff Interface:

- Go to "Digital Objects" to see all digital objects
- Use search functionality to find specific objects
- Click on digital objects to view details and linked records

#### In Public Interface:

- Digital objects linked to published resources will be visible
- Access via: http://172.173.163.116/

### 5. **Fedora Integration**

#### Direct Fedora Access:

- **Fedora REST API:** http://172.173.163.116:8086/fcrepo/rest
- **ActiveMQ Admin:** http://172.173.163.116:8161/admin

#### Fedora API Examples:

```bash
# List all objects in Fedora
curl -u fedoraAdmin:fedoraAdmin http://172.173.163.116:8086/fcrepo/rest

# Create a new object in Fedora
curl -X POST \
  -u fedoraAdmin:fedoraAdmin \
  -H "Content-Type: text/turtle" \
  -d "@object.ttl" \
  http://172.173.163.116:8086/fcrepo/rest/my-object

# Get object metadata
curl -u fedoraAdmin:fedoraAdmin http://172.173.163.116:8086/fcrepo/rest/my-object
```

### 6. **File Upload and Storage**

#### Supported File Types:

- Images: JPG, JPEG, PNG, GIF, TIFF
- Documents: PDF, DOC, DOCX
- Audio: MP3, WAV
- Video: MP4, AVI
- Archives: ZIP, TAR

#### File Size Limits:

- Maximum file size: 100MB per file
- Configured in ArchivesSpace settings

### 7. **Best Practices**

#### Digital Object Creation:

1. **Use descriptive titles** that clearly identify the content
2. **Assign unique digital object IDs** following your institution's naming convention
3. **Include proper use statements** for rights and access information
4. **Link to appropriate archival records** for context

#### File Management:

1. **Use appropriate file formats** for long-term preservation
2. **Include technical metadata** when possible
3. **Regularly backup digital objects** stored in Fedora
4. **Monitor storage capacity** and plan for growth

#### Integration:

1. **Test the connection** between ArchivesSpace and Fedora regularly
2. **Monitor ActiveMQ** for message processing issues
3. **Document your workflows** for digital object creation and linking

### 8. **Troubleshooting**

#### Common Issues:

1. **Digital objects not appearing:**

   - Check if ArchivesSpace is properly connected to Fedora
   - Verify file upload permissions
   - Check ArchivesSpace logs for errors

2. **Fedora connection issues:**

   - Verify Fedora is running: `docker ps | grep fedora`
   - Check Fedora logs: `docker logs fedora`
   - Test Fedora API directly

3. **File upload failures:**
   - Check file size limits
   - Verify file format is supported
   - Check disk space on the server

#### Useful Commands:

```bash
# Check ArchivesSpace status
ssh azureuser@172.173.163.116 "cd /home/azureuser/archivesspace && docker-compose ps"

# Check Fedora status
ssh azureuser@172.173.163.116 "cd /home/azureuser/fedora && docker-compose ps"

# View ArchivesSpace logs
ssh azureuser@172.173.163.116 "docker logs archivesspace --tail 50"

# View Fedora logs
ssh azureuser@172.173.163.116 "docker logs fedora --tail 50"
```

### 9. **Next Steps**

1. **Create your first digital object** using the staff interface
2. **Link it to an existing archival record** or create a new one
3. **Test the public interface** to see how digital objects appear
4. **Explore the API** for programmatic access
5. **Set up regular backups** of your digital objects
6. **Consider implementing** additional preservation workflows

## Support

For additional help:

- ArchivesSpace Documentation: https://archivesspace.org/archivesspace/docs/
- Fedora Documentation: https://duraspace.org/fedora/
- ArchivesSpace Community: https://archivesspace.org/community/
