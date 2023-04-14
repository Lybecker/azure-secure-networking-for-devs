from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

class BlobStorageClient:
    _storage_account_name: str
    _blob_service_client: any

    def __init__(self, storage_account_name: str):
        self._storage_account_name = storage_account_name

    def create_container(self, container_name: str):
        blob_service_client = self._get_blob_service_client()
        blob_service_client.create_container(container_name)

    def upload_blob(self, container_name: str, file_path: str):
        blob_service_client = self._get_blob_service_client()
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=file_path)

        with open(file=file_path, mode="rb") as data:
            blob_client.upload_blob(data)

    def _get_blob_service_client(self):
        default_credential = DefaultAzureCredential()
        storage_account_url = f"https://{self._storage_account_name}.blob.core.windows.net"
        self._blob_service_client = BlobServiceClient(storage_account_url, credential=default_credential)
        return self._blob_service_client
