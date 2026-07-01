# 🚀 Ansible Deployment for Phi-3.5-Financial Infrastructure

## Overview

This Ansible playbook automates the deployment of the Phi-3.5-Financial LLM model using Ollama and Docker.

## Prerequisites

1. **Ansible 2.9+**
```bash
pip install ansible
```

2. **Docker and Docker Compose**
```bash
# Install Docker Desktop or Docker Engine
# https://docs.docker.com/get-docker/
```

3. **Python Docker Module**
```bash
pip install docker
```

4. **Jinja2**
```bash
pip install jinja2
```

## File Structure

```
ansible/
├── deploy.yml                 # Main playbook
├── inventory/
│   └── hosts                  # Ansible inventory
├── roles/
│   └── ollama/
│       ├── defaults/
│       │   └── main.yml       # Default variables
│       ├── tasks/
│       │   └── main.yml       # Tasks to execute
│       ├── handlers/
│       │   └── main.yml       # Event handlers
│       └── README.md          # Role documentation
└── README.md                  # This file
```

## Quick Start

### 1. Install Ansible and Dependencies

```bash
pip install -r requirements.txt
```

Or manually:
```bash
pip install ansible docker jinja2
```

### 2. Run the Playbook

**For localhost (local machine):**
```bash
ansible-playbook deploy.yml
```

**For remote hosts:**
```bash
ansible-playbook deploy.yml -i inventory/hosts
```

**With specific variables:**
```bash
ansible-playbook deploy.yml -e "project_dir=/custom/path"
```

### 3. Verify Deployment

```bash
# Check API health
curl http://localhost:11434/api/tags

# Check container status
docker ps | grep phi-financial

# View logs
docker logs -f phi-financial-ollama
```

## Variables

### Default Variables (roles/ollama/defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | phi-financial | Project name |
| `project_dir` | /opt/phi-financial | Project directory |
| `docker_container_name` | phi-financial-ollama | Container name |
| `api_port` | 11434 | API port |
| `model_name` | phi-financial | Model name |
| `volume_name` | ollama_data | Docker volume name |

### Inventory Variables (inventory/hosts)

All variables from the playbook can be set in the inventory file.

### Runtime Variables

Pass variables at runtime:
```bash
ansible-playbook deploy.yml -e "api_port=11435 project_dir=/custom/path"
```

## Tasks

### What the Playbook Does

1. ✅ Checks Docker prerequisites
2. ✅ Creates project directory
3. ✅ Copies deployment files (Dockerfile, Modelfile, docker-compose.yml)
4. ✅ Creates Docker network and volume
5. ✅ Builds Docker image
6. ✅ Starts container
7. ✅ Initializes Phi-3.5-Financial model
8. ✅ Tests API endpoints
9. ✅ Displays deployment summary

## Advanced Usage

### Deploy to Remote Host

1. **Setup SSH access**
```bash
ssh-keygen -t rsa
ssh-copy-id user@remote-host
```

2. **Create inventory entry**
```ini
[ollama]
remote-host ansible_host=192.168.1.100 ansible_user=ubuntu

[ollama:vars]
project_dir=/opt/phi-financial
ansible_python_interpreter=/usr/bin/python3
```

3. **Run playbook**
```bash
ansible-playbook deploy.yml -i inventory/hosts
```

### Deploy Multiple Hosts

```ini
[ollama]
host1.example.com
host2.example.com
host3.example.com

[ollama:vars]
ansible_user=ubuntu
project_dir=/opt/phi-financial
```

### Custom Configuration

Create `group_vars/ollama.yml`:
```yaml
project_dir: /custom/path
api_port: 11435
model_name: phi-financial-custom
ollama_num_parallel: 8
```

Then run:
```bash
ansible-playbook deploy.yml
```

## Troubleshooting

### Docker Module Not Found
```bash
pip install docker
```

### Permission Denied Errors
```bash
ansible-playbook deploy.yml --become --ask-become-pass
```

### Connection Refused
```bash
# Check Docker is running
docker ps

# Check API is accessible
curl http://localhost:11434/api/tags
```

### Container Won't Start
```bash
# Check logs
docker logs phi-financial-ollama

# Check disk space
df -h

# Check port is available
lsof -i :11434
```

## Common Workflows

### Full Installation
```bash
ansible-playbook deploy.yml
```

### Update Modelfile and Reinitialize
```bash
# Edit Modelfile
nano ../Modelfile

# Run playbook to rebuild
ansible-playbook deploy.yml
```

### Deploy with Custom Port
```bash
ansible-playbook deploy.yml -e "api_port=11435"
```

### Health Check Only
```bash
ansible-playbook deploy.yml -t health_check
```

## Monitoring

### View Container Logs
```bash
docker logs -f phi-financial-ollama
```

### Check Resource Usage
```bash
docker stats phi-financial-ollama
```

### Inspect API
```bash
curl http://localhost:11434/api/tags | jq .
```

## Maintenance

### Stop Container
```bash
docker stop phi-financial-ollama
```

### Start Container
```bash
docker start phi-financial-ollama
```

### Restart Container
```bash
docker restart phi-financial-ollama
```

### Remove Everything
```bash
docker-compose down -v  # From project directory
```

## Integration with CI/CD

### GitHub Actions
```yaml
- name: Deploy with Ansible
  run: |
    pip install ansible docker
    ansible-playbook ansible/deploy.yml
```

### Jenkins
```groovy
stage('Deploy') {
    steps {
        sh '''
            pip install ansible docker
            ansible-playbook ansible/deploy.yml
        '''
    }
}
```

## Best Practices

1. **Use variables** instead of hardcoding values
2. **Test locally** before deploying to remote hosts
3. **Keep inventory secure** (don't commit secrets)
4. **Monitor deployment** logs for errors
5. **Automate health checks** after deployment
6. **Use tags** for selective task execution

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Ansible Module](https://docs.ansible.com/ansible/latest/collections/community/docker/index.html)
- [Ollama Documentation](https://github.com/ollama/ollama)

## Support

For issues or questions:
1. Check logs: `docker logs phi-financial-ollama`
2. Check [troubleshooting section](#troubleshooting)
3. Review [Ansible Documentation](https://docs.ansible.com/)
