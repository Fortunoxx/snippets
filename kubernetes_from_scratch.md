# K8S Playground
## create project
`dotnet new webapi -n MyWebApi`
## Containerize the Application
```yaml
# Use the official .NET Core SDK image
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app

# Copy the .csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the application code
COPY . .

# Build the application
RUN dotnet publish -c Release -o out

# Build the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "MyWebApi.dll"]
```
## build
`docker build -t mywebapi .`
## Push the Docker Image
is this optional when we use it locally?
## Create Kubernetes Manifests
- deployment.yaml
- service.yaml
## Deploy to Kubernetes
`kubectl apply -f deployment.yaml -f service.yaml`
