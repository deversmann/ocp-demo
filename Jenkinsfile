def tag,altTag

pipeline {
  agent any
  stages{
    stage('Build in Dev') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject("estimate-dev") {
              openshift.startBuild("pi", "--wait=true")
            }
          }
        }
      }
    }
    stage('Test in Dev') {
      steps {
        sleep 5
      }
    }
    stage('Deploy to Prod (non-live)') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject("estimate-prod") {
              def route = openshift.selector("route", "pi").object()
              def backends = []
              backends.add(route.spec.to)
              backends.addAll(route.spec.alternateBackends)
              def svc = backends.find {it.weight == 100}
              tag = svc.name == "pi-green" ? "blue" : "green"
              altTag = svc.name == "pi-green" ? "green" : "blue"
              openshift.tag("estimate-dev/pi:latest", "estimate-prod/pi:prod-${tag}")
              openshift.selector("dc", "pi-${tag}").rollout().status()
            }
          }
        }
      }
    }
    stage('Integration Test in Prod (non-live)') {
      steps {
        sleep 5
      }
    }
    stage('Approve Go Live') {
      steps {
        timeout(time:15, unit:'MINUTES') {
          input message: "Go Live in Production (switch to new version)?", ok: "Go Live"
        }
      }
    }
    stage('Make Live in Prod') {
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject("estimate-prod") {
              openshift.set("route-backends", "pi", "--adjust", "pi-${tag}=100%")
              openshift.set("route-backends", "pre-pi", "--adjust", "pi-${altTag}=100%")
            }
          }
        }
      }
    }
  }
}
