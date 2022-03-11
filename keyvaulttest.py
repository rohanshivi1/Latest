#########################################################################################################################################################################################
# Aug 14th 2020 -- Rohan Sharma
#  Script Name         : keyvaulttest.py
#  Script Objective:
#  For getting the Credentials and Clone the Secrets from one KeyVault to Destination Kevault.
#       a) Get the Credentials 
#       b) Get All the Secret Names from the Keyvault
#       c) Differentiate the ones not present  
#       d) Import All secrets
#       e) sp Read GET on Source and SET on Destination
#       f) SYNC ALL

# Package Versions: 
    
#pip install azure-communication-networktraversal==1.0.0b2
#pip install azure-containerregistry==1.0.0b7
#pip install azure-core==1.21.0
#pip install azure-mgmt-cognitiveservices==13.0.0
#pip install azure-mgmt-containerservice==16.4.0
#pip install azure-mgmt-datafactory==2.1.0
#pip install azure-mgmt-keyvault==9.3.0
#pip install azure-mgmt-loganalytics==12.0.0
#pip install azure-mgmt-maintenance==2.1.0b1
#pip install azure-mgmt-policyinsights==1.1.0b2
#pip install azure-mgmt-subscription==2.0.0
#pip install azure-mixedreality-authentication==1.0.0b1
#pip install azure-mixedreality-remoterendering==1.0.0b1
#pip install azure-search-documents==11.3.0b6
#pip install azure-storage-blob-changefeed==12.0.0b3
##########################################################################################################################################################################################


from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError


# needs service principal for source and destination KV to have get,create and list permissions then export this on a command line before executing
#export AZURE_CLIENT_ID="generated app id"
#export AZURE_CLIENT_SECRET="random password"
#export AZURE_TENANT_ID="tenant id"

def get_credentials():
    credential = DefaultAzureCredential()
    return credential




def get_all_secret_names(kv_name: str,credential):
    secret_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net/", credential=credential)
    secret_properties = secret_client.list_properties_of_secrets()
    secrets_list = []
    for secret_property in secret_properties:
    # # the list doesn't include values or versions of the secrets
        
        secrets_list.append(secret_property)
        
    return secrets_list
    



def get_single_secret(kv_name: str, secret_name,credential):
    secret_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net/", credential=credential)
    secret = secret_client.get_secret(secret_name)
    return secret


def _getonly_does_not_exists_dest(source_kv_name: str,dest_kv_name: str, credential):
    all_source_secrets =  get_all_secret_names(source_kv_name,credential)
    all_dest_secrets =  get_all_secret_names(dest_kv_name,credential)

    
    s_names =[]
    d_names =[]

    for secret_name in all_source_secrets:
        s_names.append(secret_name.name)

    for secret_name in all_dest_secrets:
        d_names.append(secret_name.name)
    
    
    list_difference = [item for item in s_names if item not in d_names]

    secretName_value = {}
    for s in all_source_secrets:
         single_secret = get_single_secret(source_kv_name, str(s.name), credential)
         for item in list_difference:
             if item == single_secret.name:
                secretName_value[single_secret.name] = single_secret.value

    
    return secretName_value

def import_secrets(kv_name: str, credential,secrets_list):

    secret_client = SecretClient(vault_url=f"https://{kv_name}.vault.azure.net/", credential=credential)
    
    
    for secret_name, secret_value in secrets_list.items():
        secret = secret_client.set_secret(secret_name, secret_value)
        print(secret_name + " was added")
           
               
       


   
if __name__ == "__main__":
    destination_kv="aa-key-vault-bb-env"  
    
    ##Please put the actual KeyVault Name
    
    kv_name = "aa-key-vault-cc"
    
    ##Destination KV Name
    credential= get_credentials()
    

    all_secrets=_getonly_does_not_exists_dest(kv_name,destination_kv,credential) 
    import_secrets(destination_kv,credential,all_secrets)
