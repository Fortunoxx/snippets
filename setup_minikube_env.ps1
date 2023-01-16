New-Item -Path 'D:\DEV\' -Name 'minikube' -ItemType Directory -Force
Invoke-WebRequest -OutFile 'd:\DEV\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing

$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'D:\DEV\minikube'){ [Environment]::SetEnvironmentVariable('Path', $('{0};D:\DEV\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine) }

$env:MINIKUBE_HOME = "D:\DEV\minikube\.minikube"
minikube start
