<?hh

function main($arr) {
  try {
    if ($arr[1 << 33]) {
      var_dump($arr[1 << 33]);
    } else {
      echo "no\n";
    }
  } catch (Exception $e) { echo $e->getMessage()."\n"; }
}


<<__EntryPoint>>
function main_bug_5593564() {
$packed = array(1,2,3);
$mixed = array((1 << 33) => array("value"));

main($packed);
main($mixed);
main($mixed);
main($mixed);
}
