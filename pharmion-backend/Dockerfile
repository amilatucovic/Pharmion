FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5081
ENV ASPNETCORE_URLS=http://+:5081
ENV TZ=Europe/Sarajevo

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish "Pharmion.WebAPI/Pharmion.WebAPI.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Pharmion.WebAPI.dll"]