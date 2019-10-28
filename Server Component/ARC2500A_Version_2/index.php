<?php
    
    $isSecure = false;
    if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on') {
        $isSecure = true;
    }
    elseif (!empty($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https' || !empty($_SERVER['HTTP_X_FORWARDED_SSL']) && $_SERVER['HTTP_X_FORWARDED_SSL'] == 'on') {
        $isSecure = true;
    }
    $REQUEST_PROTOCOL = $isSecure ? 'https' : 'http';
    
    //$basePath = $_SERVER['SERVER_NAME'] . dirname($_SERVER['REQUEST_URI']);
    $basePath = $REQUEST_PROTOCOL . "://" . $_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI'];
    
    $modelsPath = "/files/models/";
    $imagesPath = "/files/images/";
    $modelsPathURI = $basePath . $modelsPath;
    $imagesPathURI = $basePath . $imagesPath;
    
    class StudentModel {
        public $name = "";
        public $fileID = "";
        public $imagePath  = "";
        public $modelPath = "";
        //public $texturePathsArray = array();
    }
 
  
    $iterator = new DirectoryIterator("." . $modelsPath);
    $fileIDs = array();
    
    foreach ($iterator as $fileInfo) {
        
        if (!$fileInfo->isDot() && ($fileInfo->GetExtension() == "zip")) {
            
            $fileName = $fileInfo->getFilename();
            $path_parts = pathinfo($fileName);
            $fileID = $path_parts['filename'];
            
            if(file_exists("." . $imagesPath . $fileID . ".jpg")){
                
                $fileIDs[] = $fileID;
            }
        }
    }
       
    asort($fileIDs); //sort alphabetically
    
    $arrayStudents = array ();
    
    foreach ($fileIDs as $fileID) {
        
        
            $studentName = ucwords(str_replace("_"," ",$fileID));
            $student1 = new StudentModel();
            $student1->name = $studentName;
            $student1->fileID = $fileID;
            $student1->imagePath  = $imagesPathURI . $fileID . ".jpg";
            $student1->modelPath  = $modelsPathURI . $fileID . ".zip";
            $arrayStudents[] = $student1;
            
        
    }
    
    echo json_encode($arrayStudents);

?>
