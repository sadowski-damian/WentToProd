FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

RUN echo "Test Dockera!" && dotnet --version
RUN sleep 60
CMD ["echo", "Test Dockera CMD"]
CMD ["dotnet", "--version"]