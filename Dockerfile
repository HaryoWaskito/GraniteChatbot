## Claude Version
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY *.csproj ./
RUN dotnet restore

COPY . ./
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

## Dotnet Version
# FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
# WORKDIR /src

# COPY . ./
# RUN dotnet restore
# RUN dotnet publish -o out

# FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
# WORKDIR /app
# COPY --from=build /app/out .

# Expose port 80
EXPOSE 80
EXPOSE 443

# Set the entry point
ENTRYPOINT ["dotnet", "GraniteChatbot.dll"]