# 1.8 Deployments/CI-CD Pipeline

The Brainex application utilizes a modern, automated deployment and CI/CD (Continuous Integration/Continuous Deployment) pipeline to ensure that the system is always up-to-date and reliable. This infrastructure allows the development team to push updates seamlessly from the local environment to the live production server.

### 1.8.1 CI/CD Infrastructure (GitHub & Railway)
The deployment pipeline is built around **Railway**, a cloud platform that provides native integration with **GitHub**. The backend repository is connected directly to the Railway service, which monitors for changes on the [main](file:///c:/Users/User/Desktop/SDGP/frontend/test/widget_test.dart#15-33) branch.

**The CI/CD Workflow:**
1.  **Code Push:** A developer pushes updated code to the GitHub repository.
2.  **Trigger:** Railway detects the push and automatically triggers a new deployment build.
3.  **Build Phase:** Railway analyzes the [requirements.txt](file:///c:/Users/User/Desktop/SDGP/backend/requirements.txt) file and installs the necessary Python dependencies.
4.  **Deployment:** Once the build is successful, the current production version is replaced by the new version with zero downtime.

*(Add Screenshot 1.8.1: A screenshot of your Railway "Deployments" tab showing the history of successful builds triggered by GitHub commits.)*

### 1.8.2 Environment Variable Management
Security is maintained by avoiding the inclusion of sensitive credentials in the source code. All secrets—including the `GEMINI_API_KEY`, `MONGODB_URI`, and `GITHUB_TOKEN`—are managed within the Railway **Variables** interface. 

**Justification:** This approach ensures that the application remains secure and portable. By decoupling configuration from the code, the team can change API keys or database strings without needing to modify the codebase itself.

*(Add Screenshot 1.8.2: A screenshot of the Railway "Variables" tab showing the key-value pairs (ensure you blur the actual secret values).)*

### 1.8.3 Infrastructure Architecture
While the Python backend is hosted on Railway for high availability and automatic scaling, the data persistence layer is managed externally on **MongoDB Atlas**. This hybrid approach provides several benefits:
-   **Reliability:** MongoDB Atlas provides a managed, global cloud database environment with automatic backups.
-   **Scalability:** Both Railway and MongoDB Atlas can scale independently as the student user base grows.
-   **Performance:** The backend connects to Atlas via specialized connection strings optimized for low-latency data retrieval.

*(Add Screenshot 1.8.3: A screenshot of your MongoDB Atlas dashboard showing the Brainex cluster and active connections.)*

### 1.8.4 Deployment Goal Justification
The choice of an automated GitHub-to-Railway pipeline was made to maximize developer productivity. By automating the deployment process, the team can focus on feature development rather than manual server management. This ensures that every bug fix or new feature is delivered to the students as quickly as possible, which is essential for an agile educational support tool.
