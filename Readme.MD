# Docker Application Deployment on AWS EKS via Terraform

This project is about deploying a Docker application on AWS EKS using Terraform.

## Project Structure

The project consists of a  Terraform files `*.tf` which is used to define the infrastructure needed for the EKS cluster.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- AWS Account
- Docker
- Terraform

### Setup

1. Clone the repository
2. Navigate to the project directory
3. Run `terraform init` to initialize your Terraform workspace
4. Run `terraform apply` to create the EKS cluster

## Deployment

The Docker application can be deployed on the EKS cluster using the `kubectl` command.

## Application Code

The application is a Flask-based web service with a REST API. It interacts with a DynamoDB table in AWS.

### app.py

This is the main application file. It sets up the Flask application and the routes for the API.

The application has the following endpoints:

- `/api/hello`: A simple hello world endpoint.
- `/api/health`: A health check endpoint that returns a status of "OK".
- `/api/get/<string:item_id>`: An endpoint to retrieve JSON data from the DynamoDB table by ID.
- `/api/update/<string:item_id>`: An endpoint to update JSON data in the DynamoDB table by ID. It expects JSON data in the request body.
- `/api/store`: An endpoint to store JSON data in the DynamoDB table. It expects JSON data in the request body.
- `/api/get-by-email/<string:email>`: An endpoint to retrieve JSON data from the DynamoDB table by customer email.

The application also includes a helper function `convert_floats_to_decimals` to convert float values to decimals, as DynamoDB does not support float types.

To run the application, use the following command:

```bash
python app.py
```

## Built With

- [Terraform](https://www.terraform.io/)
- [AWS EKS](https://aws.amazon.com/eks/)
- [Docker](https://www.docker.com/)

## Authors

- [Aritra Nag](https://github.com/aritnag)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

- Hat tip to anyone whose code was used
- Inspiration
- etc