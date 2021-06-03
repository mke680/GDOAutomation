# Powershell Based Workflow automation

Company needed workflow automation that could assist with uploading files outputed by the Kodak scanning software to a 3rd party portal.

Unfortunately because I was assisting another division it raised some unique political and technical constraints.
- The division I was assisting was not very sure what they needed and did not allow for me to scope their business requirements/
- Their own IT division was meant to assist with this task but had refused in the past resulting in reduced support and inability to change processes on their end

In the end the solution although fucntional was a far less elegent than desired as it had to bolt on to the existing environment with zero changes on their end.

V1 - Upload Single Batch of Files with Metadata to 3rd Party Portal. JSON Metadata, Configuration Files for Jar uploader\
V2 - Add Different clients. JSON Metadata reformated based on different job types. Configuration Files generator had to support multiple functions. Functions split of to ease servicing.\
V3 - Automatic detection method\
V4 - Nationwide deployment multiple network drives spread across the nation had to be mapped and scanned. Each client profile nationally had their own credentials which needed to be embdedded into the JSON generator\
V5 - Parallel uploading. Large files were causing bottle necking during uploading. Trigger file now starts the batch uploads in parallel to prevent bottlenecking due to large uploads.

Detection Method Workflow

![image](https://user-images.githubusercontent.com/55390802/120638735-d82dc380-c4b3-11eb-8a8e-9482f4abe0e2.png)


Upload Prep, Upload Execution and Exception Handling
![image](https://user-images.githubusercontent.com/55390802/120593753-43ab6d00-c483-11eb-9f5f-08575035a4a1.png)

