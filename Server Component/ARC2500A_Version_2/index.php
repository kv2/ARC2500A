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
    
    $modelsPath = $basePath . "/files/models/";
    $imagesPath = $basePath . "/files/images/";
   // $texturesPath = $basePath . "/files/textures/";
    
    class StudentModel {
        public $name = "";
        public $fileID = "";
        public $imagePath  = "";
        public $modelPath = "";
        //public $texturePathsArray = array();
    }
    
    
    $student1 = new StudentModel();
    $student1->name = "Ulysses, Daniel";
    $student1->fileID = "ulysses_daniel";
    $student1->imagePath  = $imagesPath . $student1->fileID . ".jpg";
    $student1->modelPath  = $modelsPath . $student1->fileID . ".zip";
    
    $student2 = new StudentModel();
    $student2->name = "Josh, Olivia";
    $student2->fileID = "josh_olivia";
    $student2->imagePath  = $imagesPath . $student2->fileID . ".jpg";
    $student2->modelPath  = $modelsPath . $student2->fileID . ".zip";

    $student3 = new StudentModel();
    $student3->name = "Ashly, Jaylene";
    $student3->fileID = "ashly_jaylene";
    $student3->imagePath  = $imagesPath . $student3->fileID . ".jpg";
    $student3->modelPath  = $modelsPath . $student3->fileID . ".zip";
    
    $student4 = new StudentModel();
    $student4->name = "Mike, Frank";
    $student4->fileID = "mike_frank";
    $student4->imagePath  = $imagesPath . $student4->fileID . ".jpg";
    $student4->modelPath  = $modelsPath . $student4->fileID . ".zip";
    
    $student5 = new StudentModel();
    $student5->name = "Alex, Alex";
    $student5->fileID = "alex_alex";
    $student5->imagePath  = $imagesPath . $student5->fileID . ".jpg";
    $student5->modelPath  = $modelsPath . $student5->fileID . ".zip";
    
    
    $arrayStudents = array ($student1,$student2,$student3,$student4,$student5);
    
    //var_dump($e);
    echo json_encode($arrayStudents);

?>
