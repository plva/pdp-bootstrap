## Service List for Initial Development Environment

### DevelopmentOrchestrationService
- Manages and coordinates the various microservices, scripts, and tools involved in the development process.
### CodeRepositoryService
- Utilizes Git for version control, zsh scripting for automation, and integrates with Node.js/Express/TypeScript for managing code changes and collaboration.
### BuildService
- Uses scripts and eventually a Node.js app to manage build operations, providing an API for build and deployment tasks.
### DeploymentService
- Automates the deployment of code to various environments, initially local, with potential for expansion.
### DocumentationService
- Provides documentation in HTML (via React), JSON, Markdown formats, and tools to generate clients and types in various languages.
### MonitoringService
- Offers monitoring capabilities, outputting JSON data for performance analysis and usage pattern insights.
### ViewService
- Develops a platform website for aggregating views and providing intuitive dashboards for navigation and development tasks.
### TestingService
- Manages and executes tests in various languages, ensuring reliability and performance.
### CodeTransformationService
- Provides code reflection and transformation tools for efficient development, with eventual capabilities for compiling temporary modules/functions/methods/scripts to TypeScript.
### IssueService
- Keeps track of issues and tasks.

## Services for Future Consideration (Scaling and Community)

### DistributedComputingService
- To be developed later for supporting distributed computing and cloud-based operations.
### SecurityService
- To be focused on later when the platform moves beyond local development.
### ScalabilityService
- A future service to ensure that the platform can scale efficiently under different loads.
### FeedbackService
- To be developed when the platform is ready for user feedback and community engagement.

# Setup
The development environment will bootstrap all required dependencies (and ask you to install anything that's needed) starting from bash.

The only hard requirement is running on a Mac (for Homebrew). To add support for other OSs, alter `scripts/setup.sh`.
```
./bootstrap.sh
```

# Project configuration

The `project-configuration.json` file contains the project config, and looks like the following:
```
{
	"repos": []
}
```

`repos` contains all the git repos that we are tracking.
