public with sharing class PS2PromptMgr {
  private String promptId;
  private Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

  public PS2PromptMgr() {
  }

  public PS2PromptMgr(String promptId) {
    this.promptId = promptId;
  }

  public void setPromptId(String promptId) {
    this.promptId = promptId;
  }

  public void addParameter(String key, Object value) {
    ConnectApi.WrappedValue newPropValue = new ConnectApi.WrappedValue();
    newPropValue.value = value;

    this.inputParams.put('Input:' + key, newPropValue);
  }

  public void addMapParameter(String key, String mapKey, String value) {
    Map<String, String> tmpMap = new Map<String, String>();
    tmpMap.put(mapKey, value);

    ConnectApi.WrappedValue newPropValue = new ConnectApi.WrappedValue();
    newPropValue.value = tmpMap;

    this.inputParams.put('Input:' + key, newPropValue);
  }

  public void clearParameters() {
    this.inputParams.clear();
  }

  public String executePrompt() {
    ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();

    ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
    executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
    //executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
    executeTemplateInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
    executeTemplateInput.isPreview = false;
    executeTemplateInput.inputParams = this.inputParams;

    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
      this.promptId,
      executeTemplateInput
    );
    System.debug(generationsOutput);

    System.debug('Prompt resolution: ' + (generationsOutput != null ? generationsOutput.prompt : 'no data'));
    System.debug(
      'Prompt response: ' +
      ((generationsOutput != null &&
        generationsOutput.generations != null &&
        !generationsOutput.generations.isEmpty())
        ? generationsOutput.generations[0].text
        : 'no data')
    );

    return ((generationsOutput != null &&
      generationsOutput.generations != null &&
      !generationsOutput.generations.isEmpty())
      ? generationsOutput.generations[0].text
      : null);
  }

  public static void test() {
    /*
    String contentDocumentId = '069Hr00000XOy1gIAD';
    String promptId = 'Troy_File_Test'; // 0hfHr000000gLsfIAE

    PS2PromptMgr promptUtils = new PS2PromptMgr(promptId);
    promptUtils.addMapParameter('fileInput', 'id', contentDocumentId);

    String result = promptUtils.executePrompt();
    */
  }
}