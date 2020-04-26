Class DL.AWSS3 Extends DL.LocalFile
{

ClassMethod GetAWSCredentials() As %Status
{
 //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/
 //S3-AdminAccess
 //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/S3-AdminAccess
 do ^initAWS
 quit $$$OK
}

ClassMethod AWSSignRequest(ByRef request, requeststring) As %String
{
    if '$data(^AWSCredentials) {
	    set sc=..GetAWSCredentials()
	}
    set tAccessKeyId =^AWSCredentials("AccessKeyId")
    set tSecretAccessKey = ^AWSCredentials("SecretAccessKey")
    set tDateH = $ZTS
    set tWeekDay = $P($ZDT(tDateH,11)," ",1)
    set tDate = tWeekDay_", "_$ZDT(tDateH,2,1)_" GMT"
    //w !,"Date: "_tDate
    set request.Date = tDate
    set tContentMD5 = ""
    set tContentType = ""
    //set tStringToSign = "GET"_$C(10)_tContentMD5_$C(10)_tContentType_$C(10)_tDate_$C(10)_"/"_bucket_"/"_key
    set tStringToSign = $p(requeststring," ",1)_$C(10)_tContentMD5_$C(10)_tContentType_$C(10)_tDate_$C(10)_$p(requeststring," ",2)
    
    //w !,"StringToSign (before UTF-8 conversion): "_tStringToSign
    set tStringToSignUTF8 = $ZCONVERT(tStringToSign,"O","UTF8")
    //w !,"StringToSign (after UTF-8 conversion): "_tStringToSign
    set tSignature = ##class(%SYSTEM.Encryption).HMACSHA1(tStringToSignUTF8,tSecretAccessKey)
    //w !,"Signature (before Base64 encoding): "_tSignature
    set tSignatureBase64 = ##class(%SYSTEM.Encryption).Base64Encode(tSignature)
    //w !,"Signature (after Base64 encoding): "_tSignature
    set tAuthorization = "AWS "_tAccessKeyId_":"_tSignatureBase64
    //w !,"Authorization: "_tAuthorization
    set request.Authorization=tAuthorization
    quit $$$OK
}

ClassMethod GetFileHeader(filename) As %Status
{
    //s3://iris-external-table/file3.csv
    set bucket = $p(filename,"/",3) //"deepsee-2018"
    set key=$p(filename,"/",4,*) // "test.csv"
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set server = bucket_".s3.amazonaws.com"
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set requeststring="GET "_"/"_bucket_"/"_key
    set sc= ..AWSSignRequest(request,requeststring)

    set url =  "/"_key
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice()
    set %dlstream=request.HttpResponse.Data
    Set %dlstream.LineTerminator=$char(10)
	quit $$$OK
}

ClassMethod GetFileList(location) As %Status
{
    kill %etFileList
    //s3://iris-external-table/file3.csv
    set bucket = $p(location,"/",3) 
    set key=$p(location,"/",4,*) 
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set server = bucket_".s3.amazonaws.com"
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set requeststring="GET "_"/"_bucket_"/"_key
    set sc= ..AWSSignRequest(request,requeststring)

    set url =  "/"_key
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice()
    set stream=request.HttpResponse.Data
    set data=stream.Read(32000)
    //write data
    set numkeys=$l(data,"<Key>")
    for i=1:1:numkeys-1 {
        set file=$p($p(data,"<Key>",i+1),"</Key>")
        //write !,key
        set %etFileList($I(%etFileList))=location_file
    }
    quit $$$OK
}

}