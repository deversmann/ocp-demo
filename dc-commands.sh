# create all 3 projects
oc new-project dc-cicd --display-name='CI/CD'
oc new-project dc-dev --display-name='Development'
oc new-project dc-prod --display-name='Production'

# populate ci/cd project with jenkins (v3.7) (and pipeline?)
oc project dc-cicd
oc new-app jenkins-persistent
oc create -f dc-pipeline.yaml -n dc-cicd

# setup permissions to allow tagging
oc policy add-role-to-user edit system:serviceaccount:dc-cicd:jenkins -n dc-dev
oc policy add-role-to-user edit system:serviceaccount:dc-cicd:jenkins -n dc-prod
oc policy add-role-to-user system:image-puller system:serviceaccount:dc-prod:default -n dc-dev

# setup dev project to load and build code
oc project dc-dev
oc new-app https://github.com/deversmann/openshift-workshops.git --context-dir=/dc-metro-map --image-stream=openshift/nodejs:4 --name=metro
oc expose svc/metro
oc rollout status dc/metro --watch

# the latest build for blue and green
oc tag dc-dev/metro:latest dc-prod/metro-blue:prod-blue
oc tag dc-dev/metro:latest dc-prod/metro-green:prod-green

# create deployments in prod for blue and green
oc project dc-prod
oc new-app -i metro-green:prod-green --name=metro-green
oc new-app -i metro-blue:prod-blue --name=metro-blue

# remove deployment triggers
oc set triggers dc/metro-blue --manual
oc set triggers dc/metro-green --manual

# expose blue and green on prod and pre-prod urls and preset percentages
oc expose svc/metro-green --name=metro-prod
oc expose svc/metro-blue --name=metro-pre-prod
oc set route-backends metro-prod metro-blue=0 metro-green=100
oc set route-backends metro-pre-prod metro-blue=100 metro-green=0

oc project dc-cicd
oc start-build dc-pipeline --wait=true --env=DEMO_SKIP_GOLIVE=true
oc start-build dc-pipeline --list-webhooks=github
