String fileId = "1bGAEqynlVd5kyiFBx_myj9_f_PV2bOkj";
String localExcelPath =
    '/storage/emulated/0/Download/VisitorsBackup/visitors_backup.xlsx';
String fileUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

List<String> fathers = [];
List<String> priests = [];
List<String> regionlist = [];
List<String> gradesList = [
  '1',
  '2',
  '3',
];
List<String> categoriesList = [
  'عام',
  'تجاري',
  'صناعي',
  '⠀',
];
List<String> genderList = [
  'ولد',
  'بنت',
];

final Map<String, dynamic> accountCredentials = {
  "type": "service_account",
  "project_id": "visitationapp-437521",
  "private_key_id": "2caeea16c5ca7bd63574cb82d323ef5fbc443499",
  "private_key":
      "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCP2aLBUjRNPMFE\nbJUjc2t00F3C7F6baQ/AfHySKItQ/CjGrnAViI7zqNxowrrKpfcX2NiwyoWo3tih\nfytM5P8tyyRMP+KcfUU0y52mcJdfXPEQtL3/pD1On6+h84P/Cmv7LNceIbPRLC55\n6tUXSYUP3xcOK+WiTBRwPRohSv560eRM+agoPJE3lX1ea9EyG6CF0YsPbKBnls9T\nI5un0rkqCzXAGatyYjU+m0RDCy/kffeHQG7kEQpk5aL/eXHa2HoS447oImcTjEBb\nrvIVyyfh4q2tmSlM6Qn8NeynX5lJ05Ppah1c+MxAO9xrK/XyQGpha2XhtKzaMmWt\np4YGtW6tAgMBAAECggEAHL9sfpCIWcgywpMlofJSzwNGPaqBxLK0Hm5ycb4vC2X9\nWyloxnDmSq0cMUZ7UHzm+unP8lLi78rrRakVtPYNxi/TBvb8eXQyhLjNfoIBSmJX\nXdSVJPYEd4ZDsgypvCovxsBhFEk9d6fJ+Pz0jYUYlcGqiJ8+stbb/ctEQdOMNGyZ\nq0KjrcCzEBza0Q8jfJvyIo91KfEKSP6Ag7vtpFd/lsj1KEcOdj9I/EF2yZx7ZE2n\n27LD+5j6hCAwyI36hx9nokt4KeKwerLhoHFSJ+jdTqVGQVcZcnurqJRhtAf9QvFu\nZv9t8GmNq2cMVfH4l1FBL/rtn/PCW2ZzkElWZnmQ2QKBgQDCj4fKB+EC9ML4eqaR\nXxq6G+MbFF430ZHeBkyUPFyC1cw4XqSDZH4xyb4OpS/jhGEFtinBpR1eArzJmSgu\nPRlluukFLI9LbolmfeQ4oYJLFeRuNAQwy79j5QtEahg7pFjHTusxhvuPM6oCKTUa\nVx3qMY162m+YXEhHaXsb3MAGdQKBgQC9Rp47zZoVFXZdlZAGQFN7fd8ZYPryK5XS\nqXSQJ28KSAThYFbeuJ71H5/lvDTZQ1DcWSV/uIn+xyZxItRWrTGrFEYdILG+hjlQ\nkr2mq7tJMwJcBQ5NZX9vDbhe3XSH9cpxWp4ZNdknoKCJa4mnM8IusdsZ9LzO9psH\n09+VzKBwWQKBgD4ciCMNJN5GuT+OGELsc6HaaUQp2nJDayfQJv5jzrzN+CY+wJJZ\nsJfAafZO8dzWVAr4vpfdWGS8xvws8tDgHI2HgABw20YfganAou0ZUnkaAhTUckoJ\noY4IfvJWVGol61mlbhwflYt/2NRbx2IjUZ+ENkB0H5AqVcDGgdDBRmRJAoGALw1z\nIKLH/x3KwxD/MM6k8jokUAbP24wCPtBpbbyf2gp1TCHK9qsmuQEXmuDisnANlfmD\nXPDfPTr8z3s9Fh8QDduIYo1SIm7zqJgSFXDzqgrIN1/6YjstJspeXxbmdTYhEXTZ\ngKLmTPedcQwOuEYhq8IDGbzBgyHDAHsnRfIMoGECgYAquNsiQnSTOU9ZVbfVDA+b\nbAjSqWmrLH/XHphQsRu4hkxVxaTUUR+4BHRE75hwsEEHo+uwzKoCiH4pT+9rqUz6\nRzpMwFKG4qZhZYo4jDGomVAXTSy4jen5ek/B6/hTS+uux7Tr6LCRjcKbhjySqvpP\nc1YXCDWE7xki+r2zJDZwWQ==\n-----END PRIVATE KEY-----\n",
  "client_email": "visitation@visitationapp-437521.iam.gserviceaccount.com",
  "client_id": "110967456258419655403",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url":
      "https://www.googleapis.com/robot/v1/metadata/x509/visitation%40visitationapp-437521.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
};


// account userName: ava.shenoud.3@gmail.com
// account password: avashenoudiii