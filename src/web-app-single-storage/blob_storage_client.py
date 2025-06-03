from azure.core.exceptions import ResourceExistsError
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient

class BlobStorageClient:
    _storage_account_name: str
    _blob_service_client: any
    _retry_total: int
    _timeout: int

    def __init__(self, storage_account_name: str, retry_total: int = 1, timeout: int = 5):
        self._storage_account_name = storage_account_name
        self._retry_total = retry_total
        self._timeout = timeout

    def create_container(self, container_name: str):
        blob_service_client = self._get_blob_service_client()

        try:
            blob_service_client.create_container(container_name, timeout=self._timeout)
        except ResourceExistsError:
            print(f"Container {container_name} already exists in storage account {self._storage_account_name}")

    def upload_blob(self, container_name: str, file_path: str):
        blob_service_client = self._get_blob_service_client()
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=file_path)

        with open(file=file_path, mode="rb") as data:
            try:
                blob_client.upload_blob(data, timeout=self._timeout)
            except ResourceExistsError:
                print(f"Blob already exists in container {container_name} in storage account {self._storage_account_name}")


    def get_blobs_list(self, container_name: str):
        blob_service_client = self._get_blob_service_client()
        container_client = blob_service_client.get_container_client(container_name)
        return container_client.list_blobs(timeout=self._timeout)

    def _get_blob_service_client(self):
        default_credential = DefaultAzureCredential()
        storage_account_url = f"https://{self._storage_account_name}.blob.core.windows.net"
        self._blob_service_client = BlobServiceClient(storage_account_url, credential=default_credential, retry_total=self._retry_total)
        return self._blob_service_client
