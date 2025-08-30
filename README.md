**Serverless Cross-Region Disaster Recovery**

This project demonstrates a manual, serverless approach to building a disaster recovery (DR) solution on AWS. It replicates key resources from a primary region to a secondary one, providing a 'pilot light' architecture to ensure business continuity with minimal cost.

***

### 🚀 Key Features
* **Manual Cross-Region Replication:** Instructions for manually setting up replication for services like S3 and DynamoDB.
* **DNS Failover:** Uses Amazon Route 53 to manually switch traffic to the secondary region in case of a primary region outage.
* **Cost-Effective:** Leverages the 'pay-per-use' nature of serverless services to keep the secondary region costs to a minimum.

***

### 🏗️ Architecture
The architecture consists of core components deployed in two separate AWS regions:
* **Primary Region (e.g., `us-east-1`):** The main operational environment with a live application, data, and a scheduled backup process.
* **Secondary Region (e.g., `us-west-2`):** A minimal 'pilot light' environment with replicated data and dormant compute resources ready for a failover event.
* **DNS Layer:** Amazon Route 53 with a failover routing policy to direct traffic to the healthy region.

#### Architecture Diagram

<img width="1404" height="567" alt="image" src="https://github.com/ferrindsouza/project-1-serverless-cross-region-dr/blob/main/Serverless%20Archietecture.jpg"/>



***

### 📝 Manual Setup & Configuration
Since this project does not use IaC, follow these **manual, step-by-step instructions** to deploy the solution.

1.  **Create AWS Resources in the Primary Region:**
    * **DynamoDB:** Create a new DynamoDB table. **Important:** Enable DynamoDB Streams and configure it as a Global Table.
    * **Lambda:** Manually create a new Lambda function. Copy the code from `src/lambda_function.py` into the function's editor. Configure the function's environment variables as specified in the code comments.
    * **API Gateway:** Create a new REST API and link it to the Lambda function.

2.  **Configure Cross-Region Replication:**
    * **DynamoDB:** In the DynamoDB console, go to the Global Tables tab and add the secondary region (`us-west-2`).
    * **S3:** If your project uses an S3 bucket, enable **Cross-Region Replication** in the S3 bucket properties and configure it to replicate to a bucket in the secondary region.

3.  **Set up DNS Failover in Route 53:**
    * Create a hosted zone for your domain.
    * Create a health check for your primary region's API Gateway endpoint.
    * Create two A records with a failover routing policy:
        * **Primary Record:** Points to your primary region's API Gateway, associated with the health check.
        * **Secondary Record:** Points to your secondary region's API Gateway (once it's set up), with a failover type.

4.  **Repeat for the Secondary Region:**
    * Manually repeat step 1 to create a duplicate stack of DynamoDB, Lambda, and API Gateway in the secondary region. Note that DynamoDB data will be automatically replicated, so no manual data import is needed.

***

### 💡 How to Test a Failover
1.  **Simulate an Outage:** In the primary region, manually disable or shut down a key component (e.g., change the Lambda function code to return an error, or delete the API Gateway stage).
2.  **Observe Failover:** Wait for Route 53 to detect the unhealthy state. This may take up to 60-90 seconds.
3.  **Verify:** Access your application's endpoint. Traffic should now be automatically routed to the secondary region, and your service should remain operational.
