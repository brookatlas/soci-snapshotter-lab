# soci-snapshotter-lab
1.1. create an s3 bucket for your state and change it accordingly in the provider.tf file at line 17.

1.2. create a dynamodb table with the relevant name and change it in the provider.tf file on line 18

2.0. fill the "terraform.tfvars" according to this template:
```
create=true
region=<AWS_REGION>
cluster_version = <eks_version>
cluster_name = <cluster_name> 
vpc_name= <vpc_name>
suffix= <suffix_for_vpc_and_cluster_names>
```

3.0. run "tofu init":
```
tofu init
```
4.0 run "tofu plan":
```
tofu plan -var-file="terraform.tfvars"
```
5.0 run "tofu apply":
```
tofu apply -var-file="terraform.tfvars"
```

6.0 run "aws eks update-kubeconfig --name <cluster_name> --region <aws_region>" to update kubeconfig

7.0 run "kubectl apply -f deployment-tensorflow.yaml" to test the pull time of a very large ML image
8.0 run "kubectl get pods", get the name of the created pod, then run describe on it:
```
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  96s   default-scheduler  Successfully assigned default/soci-sample-deployment-58d4ffcf9b-pv66r to ip-10-0-44-29.ec2.internal
  Normal  Pulling    95s   kubelet            Pulling image "public.ecr.aws/soci-workshop-examples/tensorflow_gpu:latest"     
  Normal  Pulled     1s    kubelet            Successfully pulled image "public.ecr.aws/soci-workshop-examples/tensorflow_gpu:latest" in 1m34.165s (1m34.165s including waiting). Image size: 3376917389 bytes.
  Normal  Created    1s    kubelet            Created container: soci-container
  Normal  Started    1s    kubelet            Started container soci-container
```

it took around 95 seconds to pull it! in scaling it can be very slow!

9.0. let's delete the deployment
"kubectl delete -f deployment-tensorflow.yaml"

10.0. copy "main-soci.tf" and replace it with "main.tf" to replace the cluster config to use "soci-snapshotter"

11.0. run "tofu apply" again:
```
tofu apply
```

this will delete the old nodegroup and create a new one including the soci snapshotter configuration

12.0. run "kubectl apply -f deployment-tensorflow.yaml" again and see how much time it takes for pulling.

here is a log output:
```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  25s   default-scheduler  Successfully assigned default/soci-sample-deployment-58d4ffcf9b-j96tt to ip-10-0-29-160.ec2.internal
  Normal  Pulling    25s   kubelet            Pulling image "public.ecr.aws/soci-workshop-examples/tensorflow_gpu:latest"
  Normal  Pulled     15s   kubelet            Successfully pulled image "public.ecr.aws/soci-workshop-examples/tensorflow_gpu:latest" in 9.258s (9.258s including waiting). Image size: 3376917389 bytes.       
  Normal  Created    15s   kubelet            Created container: soci-container
  Normal  Started    15s   kubelet            Started container soci-container
```

9 seconds pull time for a 3-4gigs image! that is amazing!


13.0 cleanup the environment
13.1 run "kubectl delete -f deployment-tensorflow.yaml"
13.2 run "tofu destroy"
13.3 done.