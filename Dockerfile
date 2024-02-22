FROM node:20

# Set exb env user
ARG EXB_USER

# Create user
SHELL ["/bin/bash", "-c"]
RUN groupadd -g $EXB_USER -o exbdeved
RUN useradd -m -u $EXB_USER -g $EXB_USER -o -s /bin/bash exbdeved

# Copy ExB sources into the container
WORKDIR /home/node
COPY --chown=$EXB_USER ./ArcGISExperienceBuilder /home/node/ArcGISExperienceBuilder

USER $EXB_USER

#Install dependencies
WORKDIR /home/node/ArcGISExperienceBuilder/client/
RUN npm ci

WORKDIR /home/node/ArcGISExperienceBuilder/server/
RUN npm ci