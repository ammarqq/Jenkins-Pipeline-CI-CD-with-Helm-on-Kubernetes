FROM nginx
EXPOSE 80
COPY index.html /usr/share/nginx/html/
CMD ["nginx", "-g", "daemon off;"]
