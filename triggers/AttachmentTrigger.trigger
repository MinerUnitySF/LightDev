/**This the trigger for attachments
** @programer: Izay Ramos-Irizarry
** @version: 2.0
** @date: 6/17/2015
*/
trigger AttachmentTrigger on Attachment (after insert, after update) {
    //Call the emailServiceWorkOrder from AttachmentHelper class
	AttachmentHelper.manageServiceReport(Trigger.New);
}