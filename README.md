# moodle-docker

A Docker image with the latest version of Moodle and its requirements.

It is rebuilt (to get last minor version) every two weeks using GitHub Actions (as long as I have enough credits).

The goal is to prepare it for load balancing via Kubernetes or Docker Swarm.

Feel free to share any ideas to improve it via Issues.

The Docker Compose file makes it ready for direct deployment over plain HTTP, but it requires a reverse proxy for HTTPS.
