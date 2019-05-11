helm init --client-only --skip-refresh

helm upgrade \
         --install --force --wait \
         --timeout 900 \
         --set Image=ammarqqqq/nginx-test \
         --set ImageTag=$image_tag \
         --namespace=newegg \
         newegg \
         charts/newegg-nginx