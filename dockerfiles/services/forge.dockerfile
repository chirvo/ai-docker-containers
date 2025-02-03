# FIXME: Installation instructions fro the GH repo won't work
FROM chirvo/services/a1111

WORKDIR /app
RUN git config user.email "me@chirvo.com"
RUN git config user.name "Chirvo"
RUN git config pull.rebase true
RUN git fetch --all --tags
RUN git remote add forge https://github.com/lllyasviel/stable-diffusion-webui-forge
RUN git checkout --detach tags/v1.10.1
RUN git branch lllyasviel/main
RUN git checkout lllyasviel/main
RUN git fetch forge
RUN git branch -u forge/main
# RUN git rm CHANGELOG.md
# RUN git commit -a -m "rm CHANGELOG.md"
RUN git pull -Xignore-space-at-eol

#CMD python3 launch.py --listen --precision full --no-half --enable-insecure-extension-access