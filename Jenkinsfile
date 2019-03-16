#!groovy
def label = "worker-${UUID.randomUUID().toString()}"
podTemplate(label: label, containers: [
    containerTemplate(name: 'jnlp', image: 'lachlanevenson/jnlp-slave:3.10-1-alpine', args: '${computer.jnlpmac} ${computer.name}', workingDir: '/home/jenkins', resourceRequestCpu: '200m', resourceLimitCpu: '300m', resourceRequestMemory: '256Mi', resourceLimitMemory: '512Mi'),
    containerTemplate(name: 'docker', image: 'docker', command: 'cat', ttyEnabled: true),
    // containerTemplate(name: 'golang', image: 'golang:1.8.3', command: 'cat', ttyEnabled: true),
                                                                            //  , kubeconfig=.kube-config
    containerTemplate(name: 'helm', image: 'lachlanevenson/k8s-helm:v2.6.0', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'kubectl', image: 'lachlanevenson/k8s-kubectl:v1.4.8', command: 'cat', ttyEnabled: true)
],
volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
]){
        node(label) {
        def externalMethod

        try {
            deleteDir()

// def  kubectlTest() {
//         // Test that kubectl can correctly communication with the Kubernetes API
//     echo "running kubectl test"
//     sh "kubectl get nodes"


// }
// def helmLint(String chart_dir) {
//     container('helm') {
//     // lint helm chart
//     sh "/usr/local/bin/helm lint ${chart_dir}"


// def helmDeploy(Map args) {
//     //configure helm client and confirm tiller process is installed
// container('helm'){
//     if (args.dry_run) {
//         println "Running dry-run deployment"

//         sh "/usr/local/bin/helm upgrade --dry-run --debug --install ${args.name} ${args.chart_dir} --set ImageTag=${args.tag},Replicas=${args.replicas},Cpu=${args.cpu},Memory=${args.memory},DomainName=${args.name} --namespace=${args.name}"
//     } else {
//         println "Running deployment"
//         sh "/usr/local/bin/helm upgrade --install ${args.name} ${args.chart_dir} --set ImageTag=${args.tag},Replicas=${args.replicas},Cpu=${args.cpu},Memory=${args.memory},DomainName=${args.name} --namespace=${args.name}"

//         echo "Application ${args.name} successfully deployed. Use helm status ${args.name} to check"
//     }
// }
// }



node(label) {

    
    // Setup the Docker Registry (Docker Hub) + Credentials 
    registry_url = "https://index.docker.io/v1/" // Docker Hub
    docker_creds_id = "dockerhub" // name of the Jenkins Credentials ID
    build_tag = "${env.BUILD_ID}" // default tag to push for to the registry
    
    def pwd = pwd()
    def chart_dir = "${pwd}/charts/newegg-nginx"
        
    stage 'Checking out GitHub Repo'
    git url: 'https://github.com/ammarqq/Jenkins-Pipeline-CI-CD-with-Helm-on-Kubernetes.git'
    
    def inputFile = readFile('config.json')
    def config = new groovy.json.JsonSlurperClassic().parseText(inputFile)
    println "pipeline config ==> ${config}"
    
    stage 'Building Nginx Container for Docker Hub'
    container('docker'){
    docker.withRegistry("${registry_url}", "${docker_creds_id}") {
    
        // Set up the container to build 
        maintainer_name = "ammarqqqq"
        container_name = "nginx-test"
        
        
        stage "Building"
        
        echo "Building Nginx with docker.build(${maintainer_name}/${container_name}:${build_tag})"
        
        container = docker.build("${maintainer_name}/${container_name}:${build_tag}", '.')
        
        try {
            
            // Start Testing
            stage "Running Nginx container"
            
            // Run the container with the env file, mounted volumes and the ports:
            docker.image("${maintainer_name}/${container_name}:${build_tag}").withRun("--name=${container_name}  -p 80:80 ")  { c ->
                   
                // wait for the django server to be ready for testing
                // the 'waitUntil' block needs to return true to stop waiting
                // in the future this will be handy to specify waiting for a max interval: 
                // https://issues.jenkins-ci.org/browse/JENKINS-29037
                //
                // waitUntil {
                //     sh "ss -antup | grep 80 | grep LISTEN | wc -l | tr -d '\n' > /tmp/wait_results"
                //     wait_results = readFile '/tmp/wait_results'

                //     echo "Wait Results(${wait_results})"
                //     if ("${wait_results}" == "1")
                //     {
                //         echo "Nginx is listening on port 80"
                //         sh "rm -f /tmp/wait_results"
                //         return true
                //     }
                //     else
                //     {
                //         echo "Nginx is not listening on port 80 yet"
                //         return false
                //     }
                // } // end of waitUntil
                
                // At this point Nginx is running
                echo "Docker Container is running"
                input 'You can Check the running Docker Container on docker builder server now! Click process to the next stage!!'    
                // this pipeline is using 3 tests 
                // by setting it to more than 3 you can test the error handling and see the pipeline Stage View error message
                MAX_TESTS = 3
                for (test_num = 0; test_num < MAX_TESTS; test_num++) {     
                   
                    echo "Running Test(${test_num})"
                
                    expected_results = 0
                    if (test_num == 0 ) 
                    {
                        // Test we can download the home page from the running django docker container
                        sh "docker exec -t ${container_name} curl -s http://localhost | grep Welcome | wc -l | tr -d '\n' > /tmp/test_results" 
                        expected_results = 1
                    }
                    else if (test_num == 1)
                    {
                        // Test that port 80 is exposed
                        echo "Exposed Docker Ports:"
                        sh "docker inspect --format '{{ (.NetworkSettings.Ports) }}' ${container_name}"
                        sh "docker inspect --format '{{ (.NetworkSettings.Ports) }}' ${container_name} | grep map | grep '80/tcp:' | wc -l | tr -d '\n' > /tmp/test_results"
                        expected_results = 1
                    }
                    else if (test_num == 2)
                    {
                        // Test there's nothing established on the port since nginx is not running:
                        sh "docker exec -t ${container_name} ss -apn | grep 80 | grep ESTABLISHED | wc -l | tr -d '\n' > /tmp/test_results"
                        expected_results = 0
                    }
                    else
                    {
                        err_msg = "Missing Test(${test_num})"
                        echo "ERROR: ${err_msg}"
                        currentBuild.result = 'FAILURE'
                        error "Failed to finish container testing with Message(${err_msg})"
                    }
                    
                    // Now validate the results match the expected results
                    stage "Test(${test_num}) - Validate Results"
                    test_results = readFile '/tmp/test_results'
                    echo "Test(${test_num}) Results($test_results) == Expected(${expected_results})"
                    sh "if [ \"${test_results}\" != \"${expected_results}\" ]; then echo \" --------------------- Test(${test_num}) Failed--------------------\"; echo \" - Test(${test_num}) Failed\"; echo \" - Test(${test_num}) Failed\";exit 1; else echo \" - Test(${test_num}) Passed\"; exit 0; fi"
                    echo "Done Running Test(${test_num})"
                
                    // cleanup after the test run
                    sh "rm -f /tmp/test_results"
                    currentBuild.result = 'SUCCESS'
                }
            }
            
        } catch (Exception err) {
            err_msg = "Test had Exception(${err})"
            currentBuild.result = 'FAILURE'
            error "FAILED - Stopping build for Error(${err_msg})"
        }
        
        stage "Pushing"
        input 'Do you approve Pushing?'
        container.push()
        
        currentBuild.result = 'SUCCESS'
        
    }
    }
    stage ('helm test') {
       def dry_run = true
       def name = config.app.name
    //    def chart_dir = chart_dir
       def tag  = build_tag
       def replicas = config.app.replicas
       def cpu = config.app.cpu
       def memory = config.app.memory
        container('helm') {
    // lint helm chart
    sh "/usr/local/bin/helm lint ${chart_dir}"
    // run helm chart linter
     

    // run dry-run helm chart installation
      

       
        }
    }
    
    stage ('helm deploy') {
       def dry_run = false
       def name = config.app.name
    //    def chart_dir = chart_dir
       def tag  = build_tag
       def replicas  = config.app.replicas
       def cpu = config.app.cpu
       def memory = config.app.memory
      // Deploy using Helm chart
      container('helm'){
    if (args.dry_run) {
        println "Running dry-run deployment"

        sh "/usr/local/bin/helm upgrade --dry-run --debug --install ${args.name} ${args.chart_dir} --set ImageTag=${args.tag},Replicas=${args.replicas},Cpu=${args.cpu},Memory=${args.memory},DomainName=${args.name} --namespace=${args.name}"
    } else {
        println "Running deployment"
        sh "/usr/local/bin/helm upgrade --install ${args.name} ${args.chart_dir} --set ImageTag=${args.tag},Replicas=${args.replicas},Cpu=${args.cpu},Memory=${args.memory},DomainName=${args.name} --namespace=${args.name}"

        echo "Application ${args.name} successfully deployed. Use helm status ${args.name} to check"
    }
}


    }
    
    ///////////////////////////////////////
    //
    // Coming Soon Feature Enhancements
    //
    // 1. Add Docker Compose testing as a new Pipeline item that is initiated after this one for "Integration" testing
    // 2. Make sure to set the Pipeline's "Throttle builds" to 1 because the docker containers will collide on resources like ports and names
    // 3. Should be able to parallelize the docker.withRegistry() methods to ensure the container is running on the slave
    // 4. After the tests finish (and before they start), clean up container images to prevent stale docker image builds from affecting the current test run

}
   externalMethod.publishStatusReports()
} catch (exception) {
            throw exception
        }
}
}
