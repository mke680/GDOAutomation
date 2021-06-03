# Powershell Based Workflow automation

Company needed workflow automation that could assist with uploading files outputed by the Kodak scanning software to a 3rd party portal.

There was quite a bit of scope creep in this. Each time a version was completed the business would request more features. Instead of allowing us to scope the entire business requirement. Also because I was seconded to another division for this project they were unwilling to alter internal procedures to better suit automation forcing some very inelegent solutions to problems that shouldn't exist.

V1 - Upload Single Batch of Files with Metadata to 3rd Party Portal. JSON Metadata, Configuration Files for Jar uploader\
V2 - Add Different clients. JSON Metadata reformated based on different job types. Configuration Files generator had to support multiple functions. Functions split of to ease servicing.\
V3 - Automatic detection method\
V4 - Nationwide deployment multiple network drives spread across the nation had to be mapped and scanned. Each client profile nationally had their own credentials which needed to be embdedded into the JSON generator\
V5 - Parallel uploading. Large files were causing bottle necking during uploading. Trigger file now starts the batch uploads in parallel to prevent bottlenecking due to large uploads.

Detection Method Workflow

![image](https://user-images.githubusercontent.com/55390802/120593647-21b1ea80-c483-11eb-95fc-6de257c36918.png)

Upload Prep, Upload Execution and Exception Handling
![image](https://user-images.githubusercontent.com/55390802/120593753-43ab6d00-c483-11eb-9f5f-08575035a4a1.png)

