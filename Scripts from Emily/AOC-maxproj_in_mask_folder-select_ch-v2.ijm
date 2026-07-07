//@ File (label="Input directory",style="directory") inputdir
//@ string (label="File type", choices={".tif",".czi",".nd2",".ome.tiff"}, style="listBox") Type
//@ int(label="Channel 1 to be Sum projected", style = "spinner") Channel_1
//@ int(label="Channel 2 to be Sum projected--select 0 if none", style = "spinner") Channel_2
//@ int(label="Channel 3 to be Sum projected--select 0 if none", style = "spinner") Channel_3

//Maxproj_in_mask_folder.ijm
//Written by Emily Jie-Ning Yang


list = getFileList(inputdir);

for (i=0; i<list.length; i++) {
    showProgress(i+1, list.length);
    filename = inputdir + File.separator+ list[i];
    Folder_Mask = inputdir+File.separator+ "x-Masks";
    
     if(Type == ".ome.tiff" ){
    Fname_temp = File.getNameWithoutExtension(filename);
    Fname = File.getNameWithoutExtension(Fname_temp);   
    }
    else{
     Fname = File.getNameWithoutExtension(filename);   	
    	}
    	
     File.makeDirectory(Folder_Mask);
     
     if (endsWith(filename, Type)) {
        roiManager("reset");
        run("Bio-Formats Importer", "open=" + filename + " autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
		run("View 100%");
		Stack.getDimensions(width, height, ch, slices, frames);
		imagech = ch;
		title = getInfo("window.title");
		if(Channel_2 != 0 || Channel_3 != 0 ){
			
			run("Split Channels");
			if(Channel_1 != 0){
			selectWindow("C"+Channel_1+"-"+title);
			run("View 100%");
			Ch1_title = getInfo("window.title");
			}
			if(Channel_2 != 0){
			selectWindow("C"+Channel_2+"-"+title);
			run("View 100%");
			Ch2_title = getInfo("window.title");
			}
			if(Channel_3 != 0){
			selectWindow("C"+Channel_3+"-"+title);
			run("View 100%");
			Ch3_title = getInfo("window.title");
			}
			if(Channel_1 != 0 && Channel_2 != 0 && Channel_3 != 0 ){
			run("Merge Channels...", "c1=["+Ch1_title+"] c2=["+Ch2_title+"] c3=["+Ch3_title+"] create");
			}
			if(Channel_1 == 0 && Channel_2 != 0 && Channel_3 != 0 ){
			run("Merge Channels...", "c2=["+Ch2_title+"] c3=["+Ch3_title+"] create");			
			}
			if(Channel_1 != 0 && Channel_2 == 0 && Channel_3 != 0 ){
			run("Merge Channels...", "c1=["+Ch1_title+"] c3=["+Ch3_title+"] create");
			}
			if(Channel_1 != 0 && Channel_2 != 0 && Channel_3 == 0 ){
			run("Merge Channels...", "c1=["+Ch1_title+"] c2=["+Ch2_title+"] create");
			}
			if(Channel_1 == 0 && Channel_2 == 0 && Channel_3 != 0 ){
			run("Merge Channels...", "c3=["+Ch3_title+"] create");
			}
			if(Channel_1 == 0 && Channel_2 != 0 && Channel_3 == 0 ){
			run("Merge Channels...", "c2=["+Ch2_title+"] create");
			}
			if(Channel_1 != 0 && Channel_2 == 0 && Channel_3 == 0 ){
			run("Merge Channels...", "c1=["+Ch1_title+"] create");
			}
			
			mergedImage = getImageID();
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("tiff", Folder_Mask+File.separator+Fname+"-max");
			}
		if(Channel_2 == 0 && Channel_3 == 0 && imagech != 1 ){
		run("Split Channels");
			if(Channel_1 != 0){
			selectWindow("C"+Channel_1+"-"+title);
			BFch= getImageID();
			selectImage(BFch);
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("tiff", Folder_Mask+File.separator+Fname+"-max");
			}		
		}
		if(Channel_2 == 0 && Channel_3 == 0 && imagech == 1){
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("tiff", Folder_Mask+File.separator+Fname+"-max");
		}
		//else{
		//run("Z Project...", "projection=[Max Intensity]");
		//saveAs("tiff", Folder_Mask+File.separator+Fname+"-max");
		//}
     }
     close("*");
}
