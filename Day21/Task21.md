# Day 21/40 - Manage TLS Certificates In a Kubernetes Cluster 

## Check out the video below for Day21 👇

[![Day 21/40 - Manage TLS Certificates In a Kubernetes Cluster ](https://img.youtube.com/vi/LvPA-z8Xg4s/sddefault.jpg)](https://youtu.be/LvPA-z8Xg4s)


### Tls in Kubernetes 

![image](https://github.com/user-attachments/assets/340139b0-e5db-4e28-91eb-96cf6cedc44b)

### Client-Server model

![image](https://github.com/user-attachments/assets/316de6e9-491e-4b89-af06-0b5fe2059f4f)

### How certs are loaded

![image](https://github.com/user-attachments/assets/adf2c877-c8b0-4e87-948f-f1f78ef25e27)

### Where we use certs in control plane components

![image](https://github.com/user-attachments/assets/ec9fd842-9a25-4138-afb4-930876adb8b8)


### Commands used in the video

**To generate a key file**
```
openssl genrsa -out adam.key 2048
```

**To generate a csr file**
```
openssl req -new -key adam.key -out adam.csr -subj "/CN=adam"
```

**To approve a csr**
```
kubectl certificate approve <certificate-signing-request-name>
```

**To deny a csr**
```
kubectl certificate deny <certificate-signing-request-name>
```

**Below document can also be referred**

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatessigningrequest

Of course. Here is a comprehensive guide to help you with the exercise on working with TLS certificates in Kubernetes. This task will walk you through the manual process of generating a key, creating a Certificate Signing Request (CSR), getting it approved by the cluster's Certificate Authority (CA), and retrieving the final certificate.

This process is fundamental to securing communication within a Kubernetes cluster and is an extension of the SSL/TLS concepts discussed in the Day 20 video. While that video explained the general theory of how public/private keys and Certificate Authorities work to establish trust, this exercise applies those concepts within Kubernetes itself.

### 1. Generate a Private Key and a Certificate Signing Request (CSR)

The first step in obtaining a certificate is to generate a private key and then use that key to create a Certificate Signing Request (CSR). The private key must be kept secret, while the CSR contains the public key and identity information (like a username) that you want the Certificate Authority to sign.

We will use the **OpenSSL** utility, which is a standard tool for working with TLS certificates.

```bash
# Generate a 2048-bit RSA private key named learner.key
openssl genrsa -out learner.key 2048

# Create a Certificate Signing Request (CSR) named learner.csr
# The -subj flag sets the subject, where CN=learner defines the Common Name (username)
# and O=group1 defines the Organization (group).
openssl req -new -key learner.key -subj "/CN=learner/O=group1" -out learner.csr
```
*   **`learner.key`**: This is your new private key. It's used for decryption and should be kept secure.
*   **`learner.csr`**: This file contains your public key and the identity information you've provided. You will submit this to the Kubernetes CA to get it signed.

### 2. Create a `CertificateSigningRequest` Kubernetes Object

Now that you have the CSR file, you need to submit it to the Kubernetes API by creating a `CertificateSigningRequest` object. This object will contain the base64-encoded content of your `learner.csr` file.

1.  **Encode the CSR file**: The `request` field in the YAML manifest must be a base64-encoded string. You can encode the file and store it in a variable to make it easier to use.
    ```bash
    CSR_ENCODED=$(cat learner.csr | base64 | tr -d '\n')
    ```
2.  **Create the YAML Manifest** (`csr.yaml`): This manifest defines the `CertificateSigningRequest` object.
    *   **`expirationSeconds`**: This field specifies the desired validity period of the certificate. `604800` seconds is exactly 1 week (7 days * 24 hours * 60 minutes * 60 seconds).
    *   **`request`**: This field holds the base64-encoded CSR data. We will use the variable created above.
    *   **`signerName`**: Specifies which signer should handle the request. `kubernetes.io/kube-apiserver-client` is used for client certificates.
    *   **`usages`**: Defines what the certificate can be used for, such as `client auth`.

    ```yaml
    # csr.yaml
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: learner-csr
    spec:
      expirationSeconds: 604800 # 1 week
      request: <ENCODED_CSR_DATA> # We will replace this placeholder
      signerName: kubernetes.io/kube-apiserver-client
      usages:
        - client auth
    ```

3.  **Substitute the encoded data and apply the manifest**:
    ```bash
    # Replace the placeholder in the YAML file with the encoded CSR data
    sed -i "s|<ENCODED_CSR_DATA>|${CSR_ENCODED}|" csr.yaml
    
    # Apply the manifest to create the CSR object in the cluster
    kubectl apply -f csr.yaml
    ```
4.  **Check the CSR status**:
    ```bash
    kubectl get csr
    ```
    The output will show `learner-csr` with a `Pending` status, indicating that it's waiting for an administrator's approval.

### 3. Approve the Certificate Signing Request

By default, CSRs are not automatically approved. A cluster administrator must review and manually approve the request.

```bash
kubectl certificate approve learner-csr
```
After running this command, check the status again:
```bash
kubectl get csr
```
The status should now show `Approved,Issued`, meaning the Kubernetes CA has signed your request and issued a certificate.

### 4. Retrieve and Decode the Certificate

The signed certificate is now available within the `CertificateSigningRequest` object in the `status.certificate` field. It is also base64-encoded.

1.  **Retrieve the certificate from the CSR object**: You can use `kubectl get` with `-o jsonpath` to extract the encoded certificate data directly.
    ```bash
    kubectl get csr learner-csr -o jsonpath='{.status.certificate}'
    ```
2.  **Decode and save the certificate to a file**: Pipe the output from the previous command to the `base64 --decode` command and redirect it to a new file named `learner.crt`.
    ```bash
    kubectl get csr learner-csr -o jsonpath='{.status.certificate}' | base64 --decode > learner.crt
    ```
    You now have `learner.crt`, which is the final, signed TLS certificate ready to be used for client authentication.

### 5. Verify the Certificate

You can use OpenSSL to inspect the contents of the newly created certificate to ensure it contains the correct information.

```bash
openssl x509 -in learner.crt -text -noout
```
This command will display the certificate details. You can verify:
*   **Issuer**: It should be your Kubernetes cluster's CA.
*   **Validity**: The `Not Before` and `Not After` dates should reflect the 1-week expiration you requested.
*   **Subject**: The `CN` should be `learner` and `O` should be `group1`, matching what you specified in the CSR.

You have now successfully generated a key, created and submitted a CSR, had it approved by the cluster, and retrieved the final signed certificate. These files (`learner.key` and `learner.crt`) will be used in subsequent tasks.