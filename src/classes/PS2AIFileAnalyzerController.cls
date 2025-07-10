public without sharing class PS2AIFileAnalyzerController {
  @AuraEnabled(cacheable=false)
  public static String getPromptTemplateList() {
    String retStr = null;
    List<Map<String, Object>> options = new List<Map<String, Object>>();

    String baseUrl = URL.getOrgDomainURL().toExternalForm();
    String endpoint = baseUrl + '/services/data/v62.0/einstein/prompt-templates?type=einstein_gpt__flex&fields=Description,MasterLabel,DeveloperName&IsActive=true';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + getSessionIdFromVFPage());
    req.setHeader('Content-Type', 'application/json');

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      System.debug('Account retrieved: ' + res.getBody());

      PromptTemplateResponse resp = (PromptTemplateResponse) JSON.deserialize(
        res.getBody(),
        PromptTemplateResponse.class
      );

      for (PromptRecord pr : resp.promptRecords) {
        Map<String, Object> tempMap = new Map<String, Object>();

        tempMap.put('label', pr.fields.MasterLabel.value);
        tempMap.put('value', pr.fields.DeveloperName.value);

        if (pr.fields.Description != null && pr.fields.Description != null)
        {
            tempMap.put('description', pr.fields.Description.value);
        }
        
        options.add(tempMap);
      }

      System.debug(JSON.serializePretty(options));
      retStr = JSON.serialize(options);
    } else {
      System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
    }

    return retStr;
  }

  public static String getSessionIdFromVFPage() {
    String content = Page.SessionID.getContent().toString();
    Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
      e = content.indexOf('End_Of_Session_Id');
    return content.substring(s, e);
  }

  @AuraEnabled(cacheable=false)
  public static String getObjectName(String recordId) {
    // Get the SObject type token from the Id
    Schema.SObjectType sObjectTypeToken = Id.valueOf(recordId).getSObjectType();

    // Get the DescribeSObjectResult for the SObject type
    Schema.DescribeSObjectResult describeResult = sObjectTypeToken.getDescribe();

    // Get the object's API name
    String objectName = describeResult.getName();

    return objectName;
  }

  @AuraEnabled(cacheable=false)
  public static void storeAIAnalysis(String recordId, String analysisResult, String fieldName) {

    String objectName = getObjectName(recordId);

    SObject newObj = (SObject) Type.forName(objectName).newInstance();

    newObj.put('Id', recordId);
    newObj.put(fieldName, analysisResult);

    update newObj;
  }

  @AuraEnabled(cacheable=false)
  public static String getRecordDocuments(String recordId) {
    List<Map<String, Object>> options = new List<Map<String, Object>>();
    List<Id> idList = new List<Id>();

    idList.add(recordId);

    List<EmailMessage> emails = [SELECT Id FROM EmailMessage WHERE RelatedToId = :recordId AND HasAttachment=true];
    if (emails != null && emails.size() > 0) {
      for (EmailMessage email : emails) {
        idList.add(email.Id);
      }
    }

    List<ContentDocumentLink> links = [
      SELECT
        ContentDocumentId,
        ContentDocument.Title,
        ContentDocument.FileType,
        ContentDocument.ContentSize,
        Id,
        IsDeleted,
        LinkedEntityId,
        ShareType,
        SystemModstamp,
        Visibility,
        ContentDocument.IsArchived
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :idList AND IsDeleted = FALSE AND ContentDocument.IsArchived = FALSE
    ];

    for (ContentDocumentLink link : links) {
      Map<String, Object> tempMap = new Map<String, Object>();
      tempMap.put('value', link.ContentDocumentId);
      tempMap.put(
        'label',
        link.ContentDocument.Title +
          ' (' +
          link.ContentDocument.FileType +
          ' - ' +
          (link.ContentDocument.ContentSize / 1024.0).setScale(1) +
          ' KB)'
      );
      options.add(tempMap);
    }

    System.debug(JSON.serialize(options));
    return JSON.serialize(options);
  }

  @AuraEnabled(cacheable=false)
  public static String analyzeFile(String promptId, String fileId) {
    try {
      PS2PromptMgr promptMgt = new PS2PromptMgr(promptId);
      promptMgt.addMapParameter('fileInput', 'id', fileId);

      String result = promptMgt.executePrompt();
      return result;

    } catch (Exception e) {
      System.debug('Error calling Einstein: ' + e.getMessage());
      return 'Error: ' + e.getMessage();
    }
  }

  public class PromptTemplateResponse {
    @AuraEnabled
    public Boolean hasMoreRecords;
    @AuraEnabled
    public List<PromptRecord> promptRecords;
    @AuraEnabled
    public Integer totalPromptRecords;

    /*
    public static PromptTemplateResponse parse(String jsonString) {
      return (PromptTemplateResponse) JSON.deserialize(jsonString, PromptTemplateResponse.class);
    }
    */
  }

  public class PromptRecord {
    @AuraEnabled
    public String apiName;
    @AuraEnabled
    public Fields fields;
    @AuraEnabled
    public String id;
    @AuraEnabled
    public Boolean isStandard;
  }

  public class Fields {
    @AuraEnabled
    public FieldDetail Type;
    @AuraEnabled
    public FieldDetail IsActive;
    @AuraEnabled
    public FieldDetail MasterLabel;
    @AuraEnabled
    public FieldDetail Id;
    @AuraEnabled
    public FieldDetail DeveloperName;
    @AuraEnabled
    public FieldDetail Description;
  }

  public class FieldDetail {
    @AuraEnabled
    public String displayValue;
    @AuraEnabled
    public String value;
  }
}