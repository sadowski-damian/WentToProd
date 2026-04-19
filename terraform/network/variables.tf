# Port number our .NET app is listening on inside the Docker container
variable "app_port" {
  type        = number
  description = "Port number for our .net app"
  default     = 8080
}