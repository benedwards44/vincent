global with sharing class CalendarController {   
    
    // Fields which are Blocked from appearing in the Field Select List.
    public static final set<String> DATETIMEFIELD_REJECT_LIST = new set<String>{'CreatedDate','LastActivityDate','LastModifiedDate','SystemModstamp'};

    // LBPAM Fields which are Blocked from appearing in the filter List.
    public static final set<String> LBPAM_REJECT_LIST = new set<String>{'RecordTypeId','WhatId','AccountId','Id','OwnerId','WhoId','CreatedById','LastModifiedById','RecurrenceActivityId','IsPrivate','CreatedDate','LastActivityDate','LastModifiedDate','SystemModstamp'};
	
	// Objects which are blocked from the Object Select List
	public static final set<String> SOBJECT_REJECT_LIST = new set<String>{'accountcontactrole', 'approval', 'apextestqueueitem', 'attachment', 'campaignmember',
																'campaignmemberstatus', 'casecomment', 'casecontactrole', 'casesolution', 'partner', 'solution',
																'caseteammember', 'caseteamrole', 'caseteamtemplate', 'caseteamtemplatemember', 'product2', 'record_colour__c',
																'caseteamtemplaterecord', 'collaborationgroup', 'collaborationgroupmember', 'pricebookentry',
																'collaborationgroupmemberrequest', 'collaborationinvitation', 'contractcontactrole', 'userrole',
																'emailtemplate', 'feedcomment', 'feeditem', 'group', 'groupmember', 'opportunitycontactrole',
																'queuesobject', 'pushtopic', 'document', 'ideacomment', 'categorydata', 'opportunitylineitem',
																'contentversion', 'entitysubscription', 'idea', 'note', 'opportunitycompetitor', 'vote', 'pricebook2',
																'permissionset', 'contentdocumentlink', 'permissionsetassignment', 'calendar_setting__c',
																'fieldpermissions', 'objectpermissions'};
	
	public static final Map<String,String> objectNameFieldMap = new Map<String, String>{'case' => 'type', 'event' => 'subject', 'task' => 'subject'};										
    
    // Javascript Flags
    public static Boolean isNullValues = false;
    public static Boolean isContradiction = false;
    public static Boolean isEditable = true;
     
    public static List<String> userWarnings;
    
    public static final String QUERY_LIMIT = ' LIMIT 1000';
    public static final String ID_CNST = 'id';
    public static final String TITLE = 'title';
    public static final String START = 'start';
    public static final String E_ND = 'end';
    public static final String DA_TE = 'DATE';
	public static final String COLOR = 'color';
	public static final String NO_OVER_RIDE = '/e?nooverride=1';
	public static final String SELECT_ID_FROM = 'SELECT id FROM ';
    public static final String SELECT_ID = 'SELECT id, ';
    public static final String ORDER_BY = ' ORDER BY ';
    public static final String FR_OM = ' FROM ';
    public static final String CAMPAIGN = 'campaign';
    public static final String START_DATE = 'StartDate';
    public static final String END_DATE = 'EndDate';
    public static final String OWNER_ID = 'resource';
    public static final String RESOURCE = 'resource';
    public static final String START_FORMAT = 'yyyy-MM-dd 9:00';
    public static final String END_FORMAT = 'yyyy-MM-dd 19:00';    
    //
    public static final String LBPAM_COMP_FIELDS = 'IsAllDayEvent, IsPrivate, recordType.Name, owner.name, Location, DCRB__c, type_intervention__c, population__c, statut_de_l_intervention__c, programme__c, whatId, whoId,recordTypeId,';
    
    global static Map<id,sObject> sObjectMap{get;set;}
    private static Map<String, Map<String, Schema.SObjectField>> objectFieldDescribeMap;
    
    
    //Get the list of Salesforce Object Names
    @RemoteAction
    public static List<cSelect> getObjectsList(){

    	List<SelectOption> sfObjects = new List<SelectOption>();
    	List<String> describeKeyList = new List<String>();
    	List<String> sfObjectNames = new List<String>();
    	List<cSelect> cOptions = new List<cSelect>();
    	
    	Map<String, Schema.SObjectType> gMap = new Map<String, Schema.SObjectType>();
    	gMap = Schema.getGlobalDescribe();
    	// This code block scrutinizes and eleminates sObjects from appearing in the sObject picklist
    	// Criteria 1 : Do not allow Object from the Black List SOBJECT_REJECT_LIST
    	// Criteria 2 : Eliminate Objects from Managed Packages
    	for(String keyElement : gMap.keySet()){
    		describeKeyList.add(keyElement);
    	}
    	
    	for(Integer i = 0 ; i < describeKeyList.size() ; i++) {
    		String objectName = describeKeyList.get(i);
    		if(gMap.get(objectName).getDescribe().getName().split('__').size() < 3
    		   && !SOBJECT_REJECT_LIST.contains(objectName)){
    				sfObjectNames.add(objectName);
    		}
    	}
    	sfObjectNames.sort();
    	
    	// Add picklist value as Label against Object name value
    	for(String objectName: sfObjectNames){
    		if(gMap.get(objectName).getDescribe().isQueryable() &&
    			gMap.get(objectName).getDescribe().isCreateable() && 
    			!gMap.get(objectName).getDescribe().isDeprecatedAndHidden()){
		    			cSelect cs = new cSelect();
		    			cs.label = objectName;
		    			cs.value = gMap.get(objectName).getDescribe().getLabel();
		    			cOptions.add(cs);
    		}
    	}
    	
    	return cOptions;
    }
    
    @RemoteAction
    // Get only the Date or DateTime fields
    public static List<CSelect> getDateTimeFieldList(String objectName){

    	return getAllFieldList(objectName,false);

    }
    
    // Get the list of Salesforce fields for a given Object
    @RemoteAction
    public static List<CSelect> getAllFieldList(String objectName, Boolean allFields){

        List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
    	List<cSelect> cOptions = new List<cSelect>();
    	// Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap()
        fields.addAll(sortFieldList(getFieldMap(objectName).values()));
        
        for(Schema.SObjectField field: fields){
        	Schema.DescribeFieldResult f = field.getDescribe();
            cSelect cs = new cSelect();
            
            if(allFields == false) {
            	cs.value = field.getDescribe().getName();
            	
                if(!LBPAM_REJECT_LIST.contains(cs.value)){
                    cs.label = field.getDescribe().getLabel();
                    cOptions.add(cs);
                }
	    		
            } else {
            	cs.value = field.getDescribe().getName();
            	if(getFieldType(objectName, cs.value) <> null){
		    		cs.label = field.getDescribe().getLabel();
					cOptions.add(cs);
            	}
            }
        }
		
    	return cOptions;
    }
    
    
    //Query for Custom Setting
    public static List<Calendar_Setting__c> queryCustomSetting() {
    	List<Calendar_Setting__c> defaults = new List<Calendar_Setting__c>();
    	String currenUserId = UserInfo.getUserId();
	    defaults = [Select StartDate__c, EndDate__c, ObjectName__c, 
	    				   ObjectLabel__c, StartLabel__c, EndLabel__c,
	    				   Where__c, Ffname1__c, Ffopp1__c, Logical_Operator__c,
	    				   Ffval1__c, Ffname2__c, Ffopp2__c, Ffval2__c, altDateDT1__c,
	    				   altDateDT2__c
	    			FROM Calendar_Setting__c Where Name = :currenUserId];
	    return defaults;
    }
    
    //Get the Default query from Custom Setting
    @RemoteAction
    public static List<Calendar_Setting__c> getDefaultSetting (){
	   
	    List<Calendar_Setting__c> defaults = new List<Calendar_Setting__c>();
	    defaults = queryCustomSetting();
	    return defaults;

    }
    
    
    //Check if the given Object and Fields are the defaults set in Custom Setting 
    @RemoteAction
    public static Boolean isDefaultSetting (String ObjectName, String StartDate, String EndDate, Map<String, String> checkFilter){
	    List<Calendar_Setting__c> defaults = new List<Calendar_Setting__c>();
	    Calendar_Setting__c defaultSetting = new Calendar_Setting__c();
	    defaults = queryCustomSetting();
	    if(!defaults.isEmpty()) {
		    defaultSetting = defaults.get(0);
		    if( checkFilter.keyset().size() == 0 ) {
			    if (defaultSetting.StartDate__c == StartDate && defaultSetting.EndDate__c == EndDate
			    	&& defaultSetting.ObjectName__c == ObjectName) {
		            return true;
		        } else {
		        	return false;
		        }
		    } else {
				if( (defaultSetting.Ffname1__c == checkFilter.get('filterField1')) &&
					(defaultSetting.Ffopp1__c == checkFilter.get('filterOpp1')) &&
					(defaultSetting.Ffval1__c == checkFilter.get('filterVal1')) ) {
						if ( defaultSetting.Logical_Operator__c == null && checkFilter.get('conjunction') == null ) {
							return true;
						} else if ( defaultSetting.Logical_Operator__c != null && checkFilter.get('conjunction') == null ) {
							return false;
						} else {
							if ( (defaultSetting.Ffname2__c == checkFilter.get('filterField2')) &&
								 (defaultSetting.Ffopp2__c == checkFilter.get('filterOpp2')) &&
								 (defaultSetting.Ffval2__c == checkFilter.get('filterVal2')) &&
								 (defaultSetting.Logical_Operator__c == checkFilter.get('conjunction')) ) {
								 return true;
							} else {
								 return false;
							}
						}
					return true;
				}
				return false;
		    }
	    }
	    return false;
    }
    
    //Delete the Custom Setting for this particular User
    @RemoteAction
    public static Boolean deleteDefaultSetting (){
	   
	    List<Calendar_Setting__c> defaults = new List<Calendar_Setting__c>();
	    
	    defaults = queryCustomSetting();
	    
	    try{
	    	delete defaults;
        } catch(System.exception e){
            System.debug('exception : '+e);
            return false;
        }
	    
	    return true;

    }
    
    //Set the Default query to Custom Setting
    @RemoteAction
    public static Boolean setDefaultSetting (String ObjectName, String StartDate, String EndDate, String ObjectLabel, String StartLabel, String EndLabel, String whereClause, Map<String, String> currentFilter){
	    
	    List<Calendar_Setting__c> defaults = new List<Calendar_Setting__c>();
	    defaults = queryCustomSetting();
	    
	    Calendar_Setting__c defaultSetting = new Calendar_Setting__c();
		
		if( !defaults.isEmpty() ) {
			defaultSetting = defaults.get(0);
		}
		
		defaultSetting.Name = UserInfo.getUserId();
	    defaultSetting.ObjectName__c = ObjectName;
		defaultSetting.StartDate__c = StartDate;
		defaultSetting.EndDate__c = EndDate;
		defaultSetting.ObjectLabel__c = ObjectLabel;
		defaultSetting.StartLabel__c = StartLabel;
		defaultSetting.EndLabel__c = EndLabel;
		if( currentFilter.keyset().size() > 3 ) {
			defaultSetting.Where__c = whereClause;
			defaultSetting.Ffname1__c = currentFilter.get('filterField1');
			defaultSetting.Ffopp1__c = currentFilter.get('filterOpp1');
			defaultSetting.Ffval1__c = currentFilter.get('filterVal1');
			defaultSetting.altDateDT1__c = currentFilter.get('alt1');
			if( currentFilter.keyset().size() > 7 ) {
				defaultSetting.Ffname2__c = currentFilter.get('filterField2');
				defaultSetting.Ffopp2__c = currentFilter.get('filterOpp2');
				defaultSetting.Ffval2__c = currentFilter.get('filterVal2');
				defaultSetting.altDateDT2__c = currentFilter.get('alt2');
				defaultSetting.Logical_Operator__c = currentFilter.get('conjunction');
			} else {
				defaultSetting.Ffname2__c = '';
				defaultSetting.Ffopp2__c = '';
				defaultSetting.Ffval2__c = '';
				defaultSetting.altDateDT2__c = '';
				defaultSetting.Logical_Operator__c = '';
			}
		} else {
			defaultSetting.Where__c = '';
			defaultSetting.Ffname1__c = '';
			defaultSetting.Ffopp1__c = '';
			defaultSetting.Ffval1__c = '';
			defaultSetting.altDateDT1__c = '';
			defaultSetting.Ffname2__c = '';
			defaultSetting.Ffopp2__c = '';
			defaultSetting.Ffval2__c = '';
			defaultSetting.altDateDT2__c = '';
			defaultSetting.Logical_Operator__c = '';
		}
		
	    try{
	    	upsert defaultSetting;
        } catch(System.exception e){
            System.debug('exception : '+e);
            return false;
        }
	    
	    return true;

    }
    
    //Get the List of Colour Mapping Records
    @RemoteAction
    public static List<RecordColourWrapper> loadColourRecords( String sObjectName, List<String> fields, String whereClause, String startRange, String endRange ){
    	// Query the Object and Fetch all records
    	// With the set of Ids look up aginst Record Colour Object
    	// Prepare Record Color Wrapper and send it
    	system.debug('this is Load Records');
    	system.debug('sObjectName '+sObjectName);
    	system.debug('whereClause '+whereClause);
    	system.debug('startRange '+startRange);
    	system.debug('endRange '+endRange);
    	system.debug('fields '+fields);
    	Set<Id> recordIds = new Set<Id>();
        List<sObject> objectList = new List<sObject>();
        List<RecordColourWrapper> recordColourList = new List<RecordColourWrapper>();

        //build query
        String queryString = buildQuery(sObjectName, fields, whereClause);
        String startFieldType = getFieldType(sObjectName, fields.get(0));
        String endFieldType = getFieldType(sObjectName, fields.get(1));
        
        DateTime duRange = datetime.valueOf(startRange).addDays(-1);
        DateTime dlRange = datetime.valueOf(endRange).addDays(-1);
        
        // Find Field Types
        for(sObject obj: database.query(queryString)){
        	if(isFieldUpdatable (sObjectName, fields[0], fields[1]) &&
        	   (obj.get(fields.get(0)) != null && obj.get(fields.get(1)) != null)){
        	   	if( !isGreater(obj.get(fields.get(0)), obj.get(fields.get(1)), startFieldType, endFieldType) ) {
	    			if( (isGreater(obj.get(fields.get(1)), duRange, startFieldType, 'DateTime') &&
	    				!isGreater(obj.get(fields.get(1)), dlRange, startFieldType, 'DateTime')) ||
	    				(isGreater(obj.get(fields.get(0)), duRange, startFieldType, 'DateTime') &&
	    				!isGreater(obj.get(fields.get(0)), dlRange, startFieldType, 'DateTime')) ||
	    				(!isGreater(obj.get(fields.get(0)), duRange, startFieldType, 'DateTime') &&
	    				 isGreater(obj.get(fields.get(1)), dlRange, startFieldType, 'DateTime')) ) {
			    			objectList.add(obj);
			        		recordIds.add(obj.id);
        	   		}
        	   	}
    		}
        }
        
        Map<Id,String> recordIdToColour = getRecordColours(recordIds);
        
        for(sObject obj: objectList){

	        String colour = recordIdToColour.get(obj.id) <> null ? recordIdToColour.get(obj.id) : 'orange';
	        
	        /* set the list of wrappers used in teh colour picker */
	        RecordColourWrapper rcw = new RecordColourWrapper(obj.id, (String)obj.get(getNameField(sObjectName)), colour);
			recordColourList.add(rcw);
			
        }    

		return recordColourList;
    }
    
    /* helper method to sort a list of fields based on the label */
    public static List<Schema.SObjectField> sortFieldList(List<Schema.SObjectField> fields){
        List<Schema.SObjectField> sortedFields = new List<Schema.SObjectField>();
        
        for(Integer i = 0; i < fields.size() - 1; i++){
            for(Integer j = 0; j < fields.size() - 1; j++){
                if(fields[j].getDescribe().getLabel() > fields[j+1].getDescribe().getLabel()){
                    Schema.SObjectField temp = fields[j];
                    fields[j] = fields[j+1];
                    fields[j+1] = temp;
                }
            }
        }
        
        return fields;
    }
    
    //Get title of the record to display in the Calendar
    public static String getNameField(String objName) {
    	String nameField = '';
        // Deal with name field to use as Title in the Calendar
        nameField = objectNameFieldMap.containsKey(objName) ? objectNameFieldMap.get(objName) : 'name';
        return nameField;
    } 
    
    // Build the Object Query Given : Object & Condtion
    public static String buildQuery(String objName, String whereClause) {

		String objQuery = '';
		// For Alphabetical sorting the Query Resul
		String sortOrder = ORDER_BY + getNameField(objName); 
		// Dynamically build the Query
		// LBPAM Custom: add by default the IsPrivate and Location fields
		objQuery = SELECT_ID + LBPAM_COMP_FIELDS + getNameField(objName) + FR_OM + objName + whereClause + sortOrder + QUERY_LIMIT;
		
		return objQuery;
		
    }
    
    // Build the Object Query Given : Object , Fields & Condtion
    public static String buildQuery(String objName, List<String> fields, String whereClause) {

    	String queryFields = ' ';
		if(fields[0] != fields[1]) {
			// Build query string
			for(String s : fields) {
				queryFields += ', '+s;
			}
		} else { // Work around Redundant Fields
			queryFields += ', '+fields[0];
		}
		String objQuery = '';

		// LBPAM Custom: add by default the IsPrivate and Location fields
		objQuery = SELECT_ID + LBPAM_COMP_FIELDS + getNameField(objName) + queryFields + FR_OM + objName + whereClause + QUERY_LIMIT;
		return objQuery;
		
    }
    
    // Get the Field Type of given Field for the Given Object
    @RemoteAction
    public static String getFieldType(String objectName, String fieldName){

        Schema.DescribeFieldResult f = getFieldMap(objectName).get(fieldName).getDescribe();
        // Get the type of the field for filter
        if ((f.getType() == Schema.DisplayType.String) 
            || (f.getType() == Schema.DisplayType.DATE) 
            || (f.getType() == Schema.DisplayType.DateTime) 
            || (f.getTYpe() == Schema.DisplayType.Integer) 
            || (f.getType() == Schema.DisplayType.Boolean)
            || (f.getType() == Schema.DisplayType.Currency) 
            || (f.getType() == Schema.DisplayType.Picklist)){
                
            return f.getType().name();
        }
        return null;
    }
    
    // Get the Pop Up Url when the User Clicks on Calendar
    // to Create a New Event
    @RemoteAction
    public static String getNewActionUrl(String sObjectName){

        // Pass sObjectname as a Param
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sObjectName);
        
        return '/' + t.getDescribe().getKeyPrefix() + NO_OVER_RIDE;
    }
    
    //Get the Field Map for the Given Object
    private static Map<String, Schema.SObjectField> getFieldMap(String sObjectName){

        // Get the SObject describe info
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sObjectName);
        Schema.DescribeSObjectResult r = t.getDescribe();
        
        objectFieldDescribeMap = objectFieldDescribeMap == null? new Map<String, Map<String, Schema.SObjectField>>() : objectFieldDescribeMap;
        
        if(objectFieldDescribeMap.get(sObjectName) == null) {
        	
        	fieldMap = r.fields.getMap();
        	objectFieldDescribeMap.put(sObjectName, fieldMap);
        	
        } else {
        	fieldMap = objectFieldDescribeMap.get(sObjectName);
        }
        
        return fieldMap;
    }

    // Get the Picklist values for the Given Object and Field Name
    @RemoteAction
    public static String getPicklistValuesAsString(String objectName, String fieldName){

        final String OPT = '<option value="::v">::l</option>';
        String optionString = '';
        
        Schema.DescribeFieldResult f = getFieldMap(objectName).get(fieldName).getDescribe();
        
        for(Schema.PicklistEntry ple: f.getPicklistValues()){
            optionString += OPT.replace('::v',ple.getValue()).replace('::l', ple.getLabel());
        }
        
        return optionString;
    }
    
    private static Boolean isGreater(Object startVal, Object endVal, String sfType, String efType) {
    	
    	Date sdVal, edVal;
    	DateTime sdtVal, edtVal;
    	
    	if (sfType == DA_TE) {
			sdVal = (Date)startVal;
		} else {
			sdtVal = (DateTime)startVal;
			sdVal = sdtVal.date();
		}
    	if (efType == DA_TE) {
			edVal = (Date)endVal;
		} else {
			edtVal = (DateTime)endVal;
			edVal = edtVal.date();
		}
    	
    	if(sdVal > edVal){
    		return true;
    	}
    	return false;
    }
    
    // Get all the Records retrieved in Json Format
    @RemoteAction
    public static calendarData getMyObjectAsJson(List<String> fields, String objName, String whereClause) {
		calendarData cdata = new calendarData();
		String jsonString;
		
		// LBPAM add default filtering on Statut_de_l_intervention__c
		if (String.isEmpty(whereClause)){
			whereClause = ' where Statut_de_l_intervention__c != \'Annulée\' and StartDateTime > :system.now.addYears(-1) and StartDateTime < :system.now.addYears(1) ';	
		}else{
			whereClause = whereClause + ' and Statut_de_l_intervention__c != \'Annulée\' and StartDateTime > :system.now.addYears(-1) and StartDateTime < :system.now.addYears(1) ';
		}
		
		
		// Get the List of Records according to the given Criteria
		List<sObject> queryResults = database.query( buildQuery( objName, fields, whereClause) );
		
		// Create Id to Record Map
		sObjectMap = new Map<id,sObject>();
		for(sObject obj : queryResults){
			sObjectMap.put(obj.id,obj);
		}
		
		// Get all Corresponding Color Records
		Map<Id,String> recordIdToColour = getRecordColours(sObjectMap.keySet());
		
		// Get Describe Information
		Schema.SObjectType sType = Schema.getGlobalDescribe().get(objName);
		Schema.DescribeSObjectResult objectDescribeResult = sType.getDescribe();
		Map<String, Schema.SObjectField> sFieldMap = objectDescribeResult.fields.getMap();
		
		// Initialize new sObject and Json generator
		sObject obj = sType.newSObject();
		JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        // Find Field Types
        String startFieldType = getFieldType(objName, fields.get(0));
        String endFieldType = getFieldType(objName, fields.get(1));
        
        // Reset isWarning for this new Object
        isNullValues = false;
        isContradiction = false;
        isEditable = true;
        
		isEditable = isFieldUpdatable (objName, fields[0], fields[1]);
		
		// LBPAM retrieve all Users
		Map<Id,String> userMap = new Map<Id, String>();
    	for (User u :[Select Id, Name From User]){
    		userMap.put(u.Id, u.Name);
    	}	
    	
    	
    	Set<Id> idsForQuery = new Set<Id>();
    	
    	for(Integer i = 0; i < sObjectMap.size(); i++){
    		obj = sObjectMap.values()[i];
    		idsForQuery.add(String.valueOf(obj.get('WhatId')));
    		idsForQuery.add(String.valueOf(obj.get('WhoId')));
    	}
    	

    	Map<Id, String> idToNAmeMap = new Map<Id,String>();
    	
    	// LBPAM Need to be restricted using previous Lists
    	for (Account a :[Select Id, Name From Account where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}	
    	for (Asset a :[Select Id, Name From Asset where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}
    	for (Campaign a :[Select Id, Name From Campaign where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}
    	for (Case a :[Select Id, Subject From Case where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Subject);
    	}
    	for (ComptesRendus__c a :[Select Id, Name From ComptesRendus__c where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}
    	for (Contract a :[Select Id, Name From Contract where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}
    	for (Product2 a :[Select Id, Name From Product2 where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.Name);
    	}
    	for (Solution a :[Select Id, SolutionName From Solution where id in :idsForQuery]){
    		idToNAmeMap.put(a.Id, a.SolutionName);
    	}
    	for (Opportunity o :[Select Id, Name From Opportunity where id in :idsForQuery]){
    		idToNAmeMap.put(o.Id, o.Name);
    	}
    	
    	for (Contact c :[Select Id, Name From Contact where id in :idsForQuery]){
    		idToNAmeMap.put(c.Id, c.Name);
    	}
    	for (Lead l :[Select Id, Name From Lead where id in :idsForQuery]){
    		idToNAmeMap.put(l.Id, l.Name);
    	}

    	
    		
    	
        // Loop through each record to create relevant Json structure
    	for(Integer i = 0; i < sObjectMap.size(); i++){
    		obj = sObjectMap.values()[i];
    		if((obj.get(fields.get(0)) == null || obj.get(fields.get(1)) == null) && isNullValues == false) {
    			isNullValues = true;
    		}
    		if(obj.get(fields.get(0)) != null && obj.get(fields.get(1)) != null){
    			if(isGreater(obj.get(fields.get(0)), obj.get(fields.get(1)), startFieldType, endFieldType)){
    				isContradiction = true;
    			}
    			else {
		    		gen.writeStartObject();
			        gen.writeStringField(ID_CNST,obj.id);
			        
			        String eventTitle = (String)obj.get(getNameField(objName));
			        eventTitle = eventTitle == null ? objName + ' : ' + obj.id : eventTitle;
			        
			        // LBPAM event duration for proper content shrink
			        // based on a basis of 9 chars per 30mn slot
			        
			        integer slotDuration = 30;
			        integer slotChars = 8;
			        
			        DateTime dt1 = (DateTime)obj.get(fields.get(0));
			        long d1 = dt1.getTime() / 1000 / 60;  //getTime gives us milliseconds, so divide by 1000 for seconds then 60 for minutes
   					DateTime dt2 = (DateTime)obj.get(fields.get(1));
   					long d2 = dt2.getTime() / 1000 / 60;
   					double duration = d2 - d1;
			        integer slotNumber = (Integer)Math.rint(duration / slotDuration);
			        
			        if (slotNumber == 0){
			        	slotNumber = 1;
			        }
			        if (obj.get('IsAllDayEvent') == true){
			        	slotNumber = 20;
			        }
			        
			        // LBPAM truncate the EventTitle according to the Event duration
			        integer maxChars = slotNumber * slotChars;
			        if (eventTitle.length() > maxChars){	
			        	eventTitle = eventTitle.substring(0,maxChars);
			        }
			        			        
			        
			        // LBPAM add the location to the json
			        string location = String.valueOf(obj.get('Location'));		        
					string eventText = eventTitle;
					if (location != null){
						if (location.length() > maxChars){	
				        	location = location.substring(0,maxChars);
				        }
						eventText = eventText + '\n' + location;
					}
					
					// LBPAM dont display content if Event is Private or Type Abscence
			        if (obj.get('IsPrivate') == true || recordTypeMap.get(string.valueOf(obj.get('RecordTypeId'))) == 'Absence'){
			        	eventText = '';
			        }
			        
			        gen.writeStringField(TITLE, eventText);
			        
			        // Parse Date or DateTime accordingly
					// LBPAM display All Day event from first hour till last one
				    if (obj.get('IsAllDayEvent') == true){
			        	gen.writeStringField(START, String.valueOf(dt1.format(START_FORMAT)));
			        }else{			        
			        	gen.writeStringField(START, String.valueOf(dt1.format('yyyy-MM-dd HH:mm')));
					}	
					
					
					// Avoid redundant Fields
					if( fields[0] != fields[1] ){
						// LBPAM display All Day event from first hour till last one
				        if (obj.get('IsAllDayEvent') == true){
				        	gen.writeStringField(E_ND, String.valueOf(dt2.format(END_FORMAT)));
				        }else{			        
				        	gen.writeStringField(E_ND, String.valueOf(dt2.format('yyyy-MM-dd HH:mm')));
						}	
					}

                    //ownerId
                    if(obj.get(fields.get(2)) != null) {
                        gen.writeIdField(OWNER_ID, (Id)obj.get(fields.get(2)));
                    }
				
					// For records for which Colour records dont exist yet
					// Use Orange as Default Colour
					// LBPAM CUSTOM: based on RecordTypeID apply the correct colour
			        String colour = 'orange';
			        // Reunion
			        if (obj.get('RecordTypeId') == '01220000000ALTuAAO'){
			        	colour = 'purple';
			        }
			        // Action Commerciale LBPAM
			   		if (obj.get('RecordTypeId') == '01220000000ALTfAAO'){
			        	colour = 'blue';
			        }
			        // Action Commerciale CNP
		            if (obj.get('RecordTypeId') == '012w0000000AOA3AAO'){
			        	colour = 'green';
			        }
			        // Abscence
		            if (obj.get('IsPrivate') == true || obj.get('RecordTypeId') == '01220000000ALTzAAO'){
			        	colour = 'red';
			        }
		            
		            
		            gen.writeStringField(COLOR, colour);	
		            if (obj.get('subject') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('subject', '');	
		            }else{
		           		gen.writeStringField('subject', String.valueOf(obj.get('subject')));
		            }
		            if (obj.get('DCRB__c') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('dcrb', '');	
		            }else{
		           		gen.writeStringField('dcrb', String.valueOf(obj.get('DCRB__c')));
		            }
		            if (obj.get('type_intervention__c') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('type', '');	
		            }else{
		           		gen.writeStringField('type', String.valueOf(obj.get('type_intervention__c')));
		            }            
					if (obj.get('population__c') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('population', '');	
		            }else{
		           		gen.writeStringField('population', String.valueOf(obj.get('population__c')));
		            }
		            if (obj.get('whatId') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('associe', '');	
		            }else{
						if (String.valueOf(obj.get('whatId')) != null){
			    			gen.writeStringField('associe', idToNAmeMap.get(string.valueOf(obj.get('whatId'))));
			    		}else{
			    			gen.writeStringField('associe', '');
			    		}	
			    							
		            }
		            if (obj.get('OwnerId') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('attribue', '');	
		            }else{
		           		gen.writeStringField('attribue', userMap.get(string.valueOf(obj.get('OwnerId'))));
		            }
		            if (obj.get('whoId') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('nom', '');	
		            }else{
						if (String.valueOf(obj.get('whoId')) != null){
			    			gen.writeStringField('nom', idToNAmeMap.get(string.valueOf(obj.get('whoId'))));
			    		}else{
			    			gen.writeStringField('nom', '');
			    		}	
		            }
		            if (obj.get('statut_de_l_intervention__c') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('statut', '');	
		            }else{
		           		gen.writeStringField('statut', String.valueOf(obj.get('statut_de_l_intervention__c')));
		            }
		            if (obj.get('programme__c') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('programme', '');	
		            }else{
		           		gen.writeStringField('programme', String.valueOf(obj.get('programme__c')));
		            }
		            if (obj.get('recordTypeId') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('recordType', '');	
		            }else{
		            	gen.writeStringField('recordType', recordTypeMap.get(string.valueOf(obj.get('RecordTypeId'))));
		            }
		            if (obj.get('location') == null || obj.get('IsPrivate') == true){
		            	gen.writeStringField('location', '');	
		            }else{
		           		gen.writeStringField('location', String.valueOf(obj.get('location')));
		            }
			        gen.writeEndObject();
    			}
    		}
    	}
    	
    	gen.writeEndArray();
        
        jsonString = gen.getAsString();
    	
    	// Set event Data
    	cdata.eventData = jsonString;
    	
    	// Set Status values
    	cdata.status.nullValues = isNullValues;
    	cdata.status.contradictions = isContradiction;
    	cdata.status.isUpdatable = isEditable;
    	
    	return cdata;
    }

        //Query for Custom Setting
    public static List<User> queryUsers() {
        List<User> defaults = new List<User>();
        defaults = [Select Id, Name, Calendar_order__c
                    FROM User where IsActive = true order by Calendar_order__c];
        return defaults;
    }
    
    //Get the Default query from Custom Setting
    @RemoteAction
    public static List<Map<String, String>> getUsersAsJson(){

        List<User> userLi = queryUsers();
        List<Map<String, String>> userLiMap = new List<Map<String, String>>();


        for(User u : userLi) {
            Map<String, String> userNameIdMap = new Map<String, String>();
            userNameIdMap.put('name', u.Name);
            userNameIdMap.put('id', u.Id);
            userLiMap.add(userNameIdMap);

        }

        //String json = System.JSON.serialize(userLiMap);
        //System.debug(json);

        return userLiMap;

    }

        //userData cdata = new userData();

        //// Set event Data
        //cdata.userData = jsonString;
        
        //// Set Status values
        //cdata.status.nullValues = isNullValues;
        //cdata.status.contradictions = isContradiction;
        //cdata.status.isUpdatable = isEditable;
        
        //return cdata;
       
        //String jsonString;

        //List<User> defaults = new List<User>();
        //defaults = queryUsers();
        ////return defaults;

        //// Get the List of Records according to the given Criteria
        ////List<sObject> queryResults = database.query( buildQuery( ['Id','Name'],'User', '') );
        ////return JSON.serialize(defaults);


        //// Create Id to Name map
        //sObjectMap = new Map<id,sObject>();
        //for(sObject obj : defaults){
        //    //sObjectMap.put(String.valueOf( obj.get('Id') ),String.valueOf( obj.get('Name') ));
        //    sObjectMap.put(obj.id,obj);
        //}
        
        //// Get Describe Information
        //Schema.SObjectType sType = Schema.getGlobalDescribe().get('User');
        //Schema.DescribeSObjectResult objectDescribeResult = sType.getDescribe();
        //Map<String, Schema.SObjectField> sFieldMap = objectDescribeResult.fields.getMap();

        //// Initialize new sObject and Json generator
        //sObject obj = sType.newSObject();
        //JSONGenerator gen = JSON.createGenerator(true);
        //gen.writeStartArray();
        
        //// Reset isWarning for this new Object
        //isNullValues = false;
        //isContradiction = false;
        //isEditable = true;

        // // Loop through each record to create relevant Json structure
        //for(Integer i = 0; i < sObjectMap.size(); i++){
        //    obj = sObjectMap.values()[i];
        //    gen.writeStringField('id',(String)obj.get('Id'));
        //    //gen.writeFieldName('name');
        //    //gen.writeValue((String)obj.get('Name'));
        //    //gen.writeStringField('name', String.valueOf( obj.get('Name') ));
        //    gen.writeEndObject();
        //}
        
        //gen.writeEndArray();
        //jsonString = gen.getAsString();
        
    
    // Check if the Current User has Update Permissions for the given Fields
    private static Boolean isFieldUpdatable (String objectName, String fieldA, String fieldB) {
    	system.debug('Object '+objectName+'Sfield '+fieldA+'Efield '+fieldB);
    	Schema.DescribeFieldResult faDescribe = getFieldMap(objectName).get(fieldA).getDescribe();
    	Schema.DescribeFieldResult fbDescribe = getFieldMap(objectName).get(fieldA).getDescribe();
    	if( !faDescribe.isAccessible() || !fbDescribe.isAccessible() ||
    		!faDescribe.isUpdateable() || !fbDescribe.isUpdateable() ) {
    			return false;
    	}
    	return true;
    	
    }
    
    /* Get the chosen colours for the records */
    private static Map<Id, String> getRecordColours(Set<Id> recordIds){
    	/* used to set the colours of events on the calendar at load time */
    	Map<Id,String> recordIdToColour = new Map<Id,String>();
    	
    	for(Record_Colour__c rc: [SELECT foreign_key__c, colour__c FROM Record_Colour__c WHERE Foreign_Key__c IN :recordIds ORDER BY name DESC]){
    		recordIdToColour.put(rc.foreign_key__c, rc.colour__c);
    		
    	}
    	
    	return recordIdToColour;
    }
    
    // Persist the Color of Choice into Salesforce
    @RemoteAction
    public static Boolean saveColour(Id recordId, String colour){

    	Boolean result = true;
    	Record_Colour__c rc = new Record_Colour__c();
    	
    	List<Record_Colour__c> rcs = [SELECT foreign_key__c, colour__c FROM Record_Colour__c WHERE Foreign_Key__c = :recordId];
    	
    	System.debug(rcs);
    	
    	if(rcs.size() == 0){
    		rc.foreign_key__c = recordId;
    		rc.colour__c = colour;
    	}else{
    		rc = rcs[0];
    		rc.colour__c = colour;
    	}
   
    	upsert rc;
    	
    	system.debug(rc);
    	
    	return result;
    }
    
    // Parse the Given Json into Salesforce Objects and Save them to Salesforce
    @RemoteAction
    public static SaveReport saveEventObject(List<String> fields, String objName, String jsonString){

        JSONParser parser = JSON.createParser(jsonString);
        
        //build query
		String objQuery = SELECT_ID_FROM + objName + ' where IsPrivate = false';
        
        List<sObject> queryResults = database.query(objQuery);
		
		sObjectMap = new Map<id,sObject>();
		for(sObject obj : queryResults){
			sObjectMap.put(obj.id,obj);
		}
		Schema.SObjectType sType = Schema.getGlobalDescribe().get(objName);
		
        sObject obj;
        // This variable is used to gather all the object information before fetching the appropriate record
        // This allows us to gather the record information in any order. If we only use a Object var then
        // we'd need the order of fields to be guaranteed and the id field to be parsed first < not robust
        CalendarEvent theObject; 
        SaveReport sr = new SaveReport();
        try {
            while(parser.nextToken() != System.JSONToken.END_ARRAY){    
            
                if (parser.getCurrentToken() == JSONToken.START_OBJECT){
                    
                    // Creating a new object
                    theObject = new CalendarEvent();
                    obj = sType.newSObject();
                    
                }else if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    String idString;

                    if(parser.getText() == ID_CNST) {
                        parser.nextToken();
                        
                        idString = parser.getText();
                        
                        theObject.recordId = idString;
                        
                    }else if (parser.getText() == TITLE){
                        parser.nextToken();
                    
                        theObject.recordName = parser.getText();
                        
                    }else if (parser.getText() == RESOURCE){
                        parser.nextToken();
                        System.debug('VZZZZZ');
                        System.debug(parser.getText());
                    
                        theObject.ownerId = parser.getText();
                        
                    }else if (parser.getText() == START){
                        parser.nextToken();                
                    	
                    	theObject.startDate = DateTime.valueOf(parser.getText());
                    }else if (parser.getText() == E_ND){
                        parser.nextToken();                

                    	theObject.endDate = DateTime.valueOf(parser.getText());
                    }
                }else if (parser.getCurrentToken() == JSONToken.END_OBJECT){

                    obj = sObjectMap.get(theObject.recordId);
                    
					obj.put(fields.get(0),theObject.startDate);
					obj.put(fields.get(1),theObject.endDate); 
                    obj.put(fields.get(2),theObject.ownerId);  
					
                }
            }        
        
            update sObjectMap.values();
       		
        }catch(System.exception e){
            sr.isSaved = false;
	    	sr.saveException = e.getMessage();
	    	return sr;
        }
		sr.isSaved = true;
        return sr;
    }
    
    private static Map<Id, String> recordTypeMap {
    	get {
    		if (recordTypeMap == null){
    			recordTypeMap = new Map<Id, String>();
    			for (RecordType rt :[Select Id, DeveloperName From RecordType Where sObjectType = 'Event']){
    				recordTypeMap.put(rt.Id, rt.DeveloperName);
    			}
    		}
    		return recordTypeMap;
    	}
    	set;
    }

    
    // Wrapper created for sending save report to client
    public class SaveReport {
    	public Boolean isSaved;
    	public String saveException;
    	public SaveReport () {
	    	isSaved = true;
	    	saveException = '';
    	}
    }
    
    // Wrapper created to feed option values and Labels into Javascript 
    private class CSelect {
    	public String label {get;set;}
    	public String value {get;set;}
    }
    
    // Wrapper for indicating whether records contained null values 
    // Or Start Date value is greater than End Date Value (Contradiction)
    public class RecordStatus {
    	public Boolean nullValues;
    	public Boolean contradictions;
    	public Boolean isUpdatable;
    	public RecordStatus () {
	    	nullValues = false;
	    	contradictions = false;
	    	isUpdatable = true;
    	}
    }
    
    //Wrapper containing Json Event Data and Stus Flag
    public class calendarData {
    	public String eventData;
    	public RecordStatus status;
    	public calendarData (){
    		status = new RecordStatus();
    	}
    }

    //Wrapper containing Json Event Data and Stus Flag
    public class userData {
        public String userData;
        public RecordStatus status;
        public userData (){
            status = new RecordStatus();
        }
    }
    
    // Wrapper to hold Json Event Information
    private class CalendarEvent{
        public String recordName{get;set;}
        public DateTime startDate{get;set;}
        public Datetime endDate{get;set;}
        public String recordId{get;set;}
        public String ownerId{get;set;}
        
        public CalendarEvent(String recordId, String ownerId, String recordName, DateTime startDate, DateTime endDate){
            this.recordId = recordId;
            this.ownerId = ownerId;
            this.recordName = recordName;
            this.startDate = startDate;
            this.endDate = endDate;
        }
        
        public CalendarEvent(){}
    }
    
    // Wrapper to hold Color Information
    public class RecordColourWrapper{
    	public String id{get;set;}
    	public String name{get;set;}
    	public String colour{get;set;}
    	
    	public RecordColourWrapper(String id, String name, String colour){
    		this.id = id;
    		this.name = name;
    		this.colour = colour;
    	}
    }
 
}