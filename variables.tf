variable create {
    type = bool
    default = true
}

variable region {
    type = string
    default = "us-east-1"
}

variable cluster_version {
    type = string
    default = "1.33"
}

variable cluster_name {
    type = string
    default = "my-cluster"
}

variable vpc_name {
    type = string
    default = "my-vpc"
}

variable suffix {
    type = string
    default = ""
}