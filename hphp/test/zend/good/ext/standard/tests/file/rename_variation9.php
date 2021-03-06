<?hh
/* Prototype: bool rename ( string $oldname, string $newname [, resource $context] );
   Description: Renames a file or directory
*/
<<__EntryPoint>> function main(): void {
echo "\n*** Testing rename() by giving stream context as third argument ***\n";
$file_path = getenv('HPHP_TEST_TMPDIR') ?? dirname(__FILE__);

$context = stream_context_create();

// on directory
$dir_name = "$file_path/rename_variation9.phpt_dir9";
$new_dir_name = "$file_path/rename_variation9.phpt_dir9_new";

mkdir($dir_name);

var_dump( rename($dir_name, $new_dir_name, $context) );
var_dump( file_exists($dir_name) );  // expecting false
var_dump( file_exists($new_dir_name) ); // expecting true

//on file
$src_name = "$file_path/rename_variation9.tmp";
$dest_name = "$file_path/rename_variation9_new.tmp";

// create the file
$fp = fopen($src_name, "w");
$s1 = stat($src_name);
fclose($fp);

var_dump( rename($src_name, $dest_name, $context) );
var_dump( file_exists($src_name) );  // expecting false
var_dump( file_exists($dest_name) );  // expecting true

echo "Done\n";
error_reporting(0);
$file_path = getenv('HPHP_TEST_TMPDIR') ?? dirname(__FILE__);
unlink($file_path."/rename_variation9_new.tmp");
rmdir($file_path."/rename_variation9.phpt_dir9_new");
}
