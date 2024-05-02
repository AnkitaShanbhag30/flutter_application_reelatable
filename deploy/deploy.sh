#! /bin/sh
flutter build web --release --web-renderer=html
docker build --platform linux/amd64 -t gcr.io/reelatable-420506/docker-flutter-reelatable:latest .
docker push gcr.io/reelatable-420506/docker-flutter-reelatable:latest
cd deploy
kubectl apply -f flutter-reelatable-deployment.yaml
kubectl apply -f flutter-reelatable-service.yaml
cd ..
kubectl rollout restart deployment flutter-reelatable
kubectl get pods