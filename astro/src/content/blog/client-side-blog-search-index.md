---
title: 'Creating a client-side search index'
description: 'Creating a '
pubDate: 2025-12-1
draft: false
---

There should be some way for me to perform client-side
search of blog posts for filtering, using some tricks and
techniaues.

First, I can create a compressed search index based on frequently used english
terms to essentially create a large automated tag list for each blog post.

I asked claude to look at word frequency in my current blog posts.

```py
#!/usr/bin/env python3
"""
Word Frequency Counter
Counts the frequency of unique words across multiple text files.
"""

import sys
import re
from collections import Counter
from pathlib import Path


def clean_word(word):
    """
    Clean and normalize a word by converting to lowercase and removing punctuation.
    
    Args:
        word: String to clean
        
    Returns:
        Cleaned lowercase word, or None if word becomes empty after cleaning
    """
    # Remove punctuation and convert to lowercase
    cleaned = re.sub(r'[^\w\s]', '', word.lower())
    return cleaned if cleaned else None


def count_words_in_file(filepath):
    """
    Count words in a single file.
    
    Args:
        filepath: Path to the text file
        
    Returns:
        Counter object with word frequencies
    """
    word_counter = Counter()
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                # Split line into words
                words = line.split()
                # Clean and count each word
                for word in words:
                    cleaned = clean_word(word)
                    if cleaned:
                        word_counter[cleaned] += 1
        print(f"✓ Processed: {filepath}")
    except FileNotFoundError:
        print(f"✗ File not found: {filepath}", file=sys.stderr)
    except Exception as e:
        print(f"✗ Error reading {filepath}: {e}", file=sys.stderr)
    
    return word_counter


def count_words_in_files(filepaths):
    """
    Count word frequencies across multiple files.
    
    Args:
        filepaths: List of file paths to process
        
    Returns:
        Counter object with combined word frequencies
    """
    total_counter = Counter()
    
    for filepath in filepaths:
        file_counter = count_words_in_file(filepath)
        total_counter.update(file_counter)
    
    return total_counter


def display_results(word_counts, top_n=None):
    """
    Display word frequency results.
    
    Args:
        word_counts: Counter object with word frequencies
        top_n: Number of top words to display (None for all)
    """
    print("\n" + "="*60)
    print("WORD FREQUENCY RESULTS")
    print("="*60)
    
    if not word_counts:
        print("No words found.")
        return
    
    print(f"Total unique words: {len(word_counts)}")
    print(f"Total word count: {sum(word_counts.values())}")
    print("\n" + "-"*60)
    
    # Get most common words
    items = word_counts.most_common(top_n) if top_n else word_counts.most_common()
    
    # Calculate width for formatting
    max_word_len = max(len(word) for word, _ in items)
    max_count_len = len(str(max(count for _, count in items)))
    
    print(f"{'WORD':<{max_word_len}}  {'COUNT':>{max_count_len}}")
    print("-"*60)
    
    for word, count in items:
        print(f"{word:<{max_word_len}}  {count:>{max_count_len}}")


def main():
    """Main program entry point."""
    if len(sys.argv) < 2:
        print("Usage: python word_frequency.py <file1> [file2] [file3] ...")
        print("\nExample:")
        print("  python word_frequency.py document.txt")
        print("  python word_frequency.py file1.txt file2.txt file3.txt")
        sys.exit(1)
    
    # Get file paths from command line arguments
    filepaths = sys.argv[1:]
    
    print(f"Processing {len(filepaths)} file(s)...\n")
    
    # Count words across all files
    word_counts = count_words_in_files(filepaths)
    
    # Display results (show top 50 by default, or all if fewer than 50)
    display_results(word_counts, top_n=50 if len(word_counts) > 50 else None)
    
    # Option to save to file
    print("\n" + "="*60)
    save = input("Save full results to file? (y/n): ").strip().lower()
    if save == 'y':
        output_file = input("Enter output filename (default: word_frequencies.txt): ").strip()
        if not output_file:
            output_file = "word_frequencies.txt"
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write("WORD FREQUENCY RESULTS\n")
                f.write("="*60 + "\n\n")
                f.write(f"Total unique words: {len(word_counts)}\n")
                f.write(f"Total word count: {sum(word_counts.values())}\n\n")
                f.write(f"{'WORD':<30}  COUNT\n")
                f.write("-"*60 + "\n")
                
                for word, count in word_counts.most_common():
                    f.write(f"{word:<30}  {count}\n")
            
            print(f"✓ Results saved to: {output_file}")
        except Exception as e:
            print(f"✗ Error saving file: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
```


```
WORD FREQUENCY RESULTS
============================================================

Total unique words: 1635
Total word count: 5689

WORD                            COUNT
------------------------------------------------------------
the                             262
to                              133
a                               130
and                             105
00                              95
for                             78
is                              76
20                              71
image                           70
in                              69
of                              51
i                               42
that                            38
file                            38
this                            37
def                             36
be                              33
py                              32
task                            32
by                              30
run                             29
will                            29
are                             27
it                              27
on                              27
vm                              27
cloudinit                       27
tasks                           26
qemu                            26
from                            24
our                             24
virtual                         23
format                          23
not                             22
have                            22
can                             21
so                              21
if                              20
machine                         19
data                            17
thread                          17
an                              17
as                              17
todo                            17
overlay                         17
files                           17
we                              17
userdata                        17
size                            17
you                             16
using                           16
but                             16
class                           16
graph                           16
taskname                        16
time                            15
at                              15
with                            15
start                           15
create                          15
qcow2                           15
which                           14
how                             14
or                              14
all                             14
test                            14
disk                            14
has                             13
use                             13
dependencies                    13
tests                           13
now                             13
images                          13
true                            12
false                           12
need                            12
its                             12
each                            12
import                          12
backing                         12
signal                          11
event                           11
then                            11
module                          11
name                            11
once                            11
configuration                   11
base                            11
01                              11
device                          11
threads                         10
while                           10
wait                            10
runs                            10
shellsession                    10
pass                            10
set                             10
ssh                             10
ubuntuimg                       10
bytes                           10
host                            10
guest                           10
lets                            9
group                           9
make                            9
dependency                      9
pytest                          9
ubuntu                          9
running                         9
metadata                        9
cloudlocalds                    9
raw                             9
drive                           9
python                          8
when                            8
where                           8
until                           8
only                            8
there                           8
better                          8
serial                          8
os                              8
them                            8
taskgroup                       8
specify                         8
between                         8
my                              8
first                           8
taskgroupname                   8
ill                             8
sh                              8
some                            7
stop                            7
without                         7
sure                            7
over                            7
cpu                             7
than                            7
child                           7
release                         7
different                       7
port                            7
command                         7
line                            7
any                             7
could                           7
ssh_ready                       7
more                            7
order                           7
into                            7
do                              7
im                              7
o                               7
seediso                         7
4                               7
qemusystemaarch64               7
mount                           7
main                            6
control                         6
flag                            6
same                            6
asyncio                         6
timesleep1                      6
timesleep10                     6
threadingevent                  6
would                           6
process                         6
what                            6
reference                       6
inspect                         6
names                           6
type                            6
ready                           6
end                             6
no                              6
ssh_port                        6
constraints                     6
cloudconfig                     6
users                           6
qemuimg                         6
header                          6
bios                            6
ive                             5
handling                        5
raise                           5
simply                          5
interrupt                       5
queue                           5
code                            5
also                            5
look                            5
way                             5
was                             5
example                         5
execute                         5
async                           5
monitor                         5
send                            5
modules                         5
opthomebrewcellarpython3143140_1frameworkspythonframeworkversions314libpython314inspectpy  5
filename                        5
like                            5
after                           5
mermaid                         5
store                           5
port_ready                      5
been                            5
__init__self                    5
rsync                           5
should                          5
key                             5
length                          5
b                               5
m                               5
poweroff                        5
copy                            5
user                            5
seed                            5
info                            5
16                              5
called                          5
take                            5
cidata                          5
interface                       5
include                         5
patterns                        4
try                             4
flags                           4
shutdown                        4
signals                         4
uses                            4
boolean                         4
multiple                        4
manage                          4
loops                           4
introduce                       4
else                            4
execution                       4
api                             4
own                             4
must                            4
up                              4
otherwise                       4
default                         4
function                        4
check                           4
read                            4
f                               4
model                           4
even                            4
new                             4
cancel                          4
maybe                           4
down                            4
context                         4
argument                        4
perhaps                         4
diagram                         4
think                           4
node                            4
sleep_for                       4
sleep                           4
out                             4
sequencing                      4
run_once                        4
identified                      4
protocol                        4
next                            4
suite                           4
already                         4
two                             4
instanceid                      4
instancedata                    4
were                            4
formats                         4
aptget                          4
install                         4
power_state                     4
state                           4
specific                        4
591mib                          4
networking                      4
test_runimg                     4
brew                            4
prefix                          4
qemushareqemuedk2aarch64codefd  4
accel                           4
hvf                             4
smp                             4
rock                            4
label                           4
08                              4
4g                              4
performance                     4
hypervisor                      4
title                           3
claude                          3
description                     3
used                            3
pubdate                         3
draft                           3
signal_handler                  3
except                          3
handler                         3
loop                            3
handle                          3
why                             3
instead                         3
asynchronous                    3
longrunning                     3
point                           3
task_interruptible_loop         3
method                          3
difference                      3
cannot                          3
daemon                          3
before                          3
one                             3
blocks                          3
done                            3
subprocess                      3
vs                              3
debugging                       3
close                           3
just                            3
source                          3
threading                       3
cat                             3
_thread                         3
note                            3
pep                             3
8                               3
compliant                       3
those                           3
old                             3
wont                            3
able                            3
builtin                         3
parent                          3
well                            3
taskgraph                       3
__init__                        3
arguments                       3
precedence                      3
error                           3
itself                          3
their                           3
implement                       3
1s                              3
grouprun                        3
groupwait                       3
rules                           3
explicit                        3
dont                            3
readonly                        3
correctness                     3
case                            3
allows                          3
instance                        3
these                           3
path                            3
creating                        3
platform                        3
vms                             3
mac                             3
architecture                    3
curl                            3
boot                            3
define                          3
yaml                            3
final                           3
system                          3
stored                          3
config                          3
usrlocalbinsetupsh              3
root                            3
sudo                            3
simple                          3
qemus                           3
gives                           3
me                              3
sudoers                         3
public                          3
copyonwrite                     3
means                           3
vmubuntuimg                     3
591                             3
mib                             3
compat                          3
11                              3
compression                     3
cost                            3
contain                         3
theyre                          3
specification                   3
kib                             3
though                          3
display                         3
none                            3
directory                       3
find                            3
option                          3
sector                          3
blazing                         3
saddles                         3
docker                          3
v                               3
userdatacopy                    3
virt                            3
netdev                          3
nographic                       3
instruction                     3
hardware                        3
network                         3
console                         3
coding                          2
interesting                     2
various                         2
programming                     2
languages                       2
20251128                        2
stop_flagstop                   2
keyboardinterrupt               2
risk                            2
corrupting                      2
global                          2
structures                      2
dictionary                      2
useful                          2
managing                        2
object                          2
exploring                       2
together                        2
plus                            2
work                            2
eventis_set                     2
threadingthreadtargettask_interruptible_loopstart  2
eventset                        2
signalsignalsignalsigint        2
cooperative                     2
lambda                          2
waiting                         2
scenario                        2
working                         2
paused                          2
starts                          2
concurrently                    2
waits                           2
multitasking                    2
pattern                         2
terminated                      2
task_noninterruptible           2
handlers                        2
proc                            2
procstart                       2
procterminate                   2
cant                            2
resources                       2
responsibly                     2
cleaning                        2
trigger                         2
procinterrupt                   2
exiting                         2
process_id                      2
thread_id                       2
loop_id                         2
print                           2
ways                            2
coroutines                      2
pool                            2
anything                        2
output                          2
application                     2
going                           2
message                         2
emulating                       2
deque                           2
_deque                          2
originally                      2
inspired                        2
java                            2
convention                      2
being                           2
deprecated                      2
doesnt                          2
printinspectgetsource_thread    2
call                            2
lines                           2
lnum                            2
taskthread                      2
needs                           2
does                            2
satisfied                       2
single                          2
receives                        2
messages                        2
finishes                        2
queues                          2
see                             2
automatic                       2
handles                         2
stores                          2
stdout                          2
stderr                          2
kind                            2
still                           2
adds                            2
added                           2
other                           2
target                          2
super__init__fsleep             2
taskgroups                      2
sleeps                          2
groupadd_start_tasktask         2
task1                           2
task2                           2
task2depends_ontask1            2
figure                          2
sequence                        2
fact                            2
derived                         2
thats                           2
let                             2
manually                        2
overlay_image                   2
portreadytask                   2
sshreadytask                    2
ok                              2
run_onceadd_precedenceport_ready  2
p                               2
overlayimagetasktask            2
str                             2
part                            2
variables                       2
subclass                        2
yes                             2
about                           2
datadependencyqemuvmtask        2
remember                        2
both                            2
qemu_vm                         2
portreadytaskport               2
taskgroupdependencyvm           2
copied                          2
ondemand                        2
taskgroupdependency             2
var                             2
whats                           2
ordered                         2
plan                            2
paths                           2
through                         2
lot                             2
easier                          2
nice                            2
d                               2
faas                            2
functionasaservice              2
cloud                           2
they                            2
steps                           2
server                          2
m1                              2
initialization                  2
perinstance                     2
details                         2
localhostname                   2
generate                        2
required                        2
manages                         2
faasvm                          2
know                            2
initialized                     2
frequency                       2
docs                            2
permissions                     2
0755                            2
update                          2
y                               2
delay                           2
ssh_authorized_keys             2
meant                           2
uv                              2
project                         2
commands                        2
initializing                    2
exit                            2
cause                           2
emulator                        2
havent                          2
security                        2
threat                          2
giving                          2
rule                            2
finally                         2
your                            2
fun                             2
2                               2
storage                         2
needed                          2
235                             2
gib                             2
25232932864                     2
cluster_size                    2
65536                           2
information                     2
zlib                            2
lazy                            2
refcounts                       2
refcount                        2
bits                            2
corrupt                         2
extended                        2
l2                              2
takes                           2
limits                          2
paying                          2
preallocation                   2
iso                             2
introduced                      2
features                        2
extension                       2
years                           2
extensions                      2
enabling                        2
memory                          2
runner                          2
may                             2
such                            2
within                          2
environment                     2
settings                        2
stable                          2
canonical                       2
cp                              2
write                           2
enabled                         2
maximum                         2
196                             2
stdio                           2
ifvirtioformatqcow2filetestimg  2
nic                             2
open                            2
get                             2
backed                          2
debug                           2
initialize                      2
desired                         2
section                         2
available                       2
containing                      2
utility                         2
distributed                     2
maintained                      2
creates                         2
genisoimage                     2
following                       2
img                             2
volid                           2
joliet                          2
sets                            2
volume                          2
block                           2
labels                          2
iso9660                         2
2048                            2
mel                             2
brooks                          2
macos                           2
touch                           2
c                               2
e                               2
30                              2
61                              2
b7                              2
0a                              2
1c                              2
local                           2
fileseedisoifnoneformatrawreadonlyonidcidata  2
virtioblkpcidrivecidata         2
filetest_runnerimgifnoneformatqcow2idhd0  2
virtioblkpcidrivehd0            2
virtionetpcinetdevnet0          2
useridnet0                      2
arm                             2
apples                          2
framework                       2
advantage                       2
software                        2
physical                        2
characteristics                 2
ram                             2
grants                          2
backend                         2
feature                         2
cable                           2
monstdio                        2
booting                         2
faas_userlocalhost              2
checking                        2
claudecode                      1
here                            1
seen                            1
__name__                        1
__main__                        1
stop_flag                       1
event_generator                 1
minimizes                       1
spent                           1
outofband                       1
minimizing                      1
clears                          1
quickly                         1
lessening                       1
nonreentrant                    1
occurring                       1
possibly                        1
setting                         1
inprogress                      1
procedures                      1
continue                        1
lengthy                         1
pause                           1
repeated                        1
handled                         1
gracefully                      1
regular                         1
graceful                        1
shutdowns                       1
types                           1
shortrunning                    1
task_short_run                  1
threadingthreadtargettask_short_runstart  1
task_long_run                   1
threadingthreadtargettask_long_runstart  1
shortlooping                    1
task_short_loop                 1
threadingthreadtargettask_short_loopstart  1
longlooping                     1
task_long_loop                  1
threadingthreadtargettask_long_loopstart  1
respond                         1
interruptible                   1
responding                      1
flagsstopset                    1
task_interrupted_by_signal      1
flagsstopis_set                 1
threadingthreadtargettask_interrupted_by_signalstart  1
timesensitive                   1
timeouts                        1
implemented                     1
manner                          1
timer                           1
threadingtimer30                1
timerstart                      1
enables                         1
cpuefficient                    1
defers                          1
triggered                       1
requires                        1
cpuinefficient                  1
busy                            1
polling                         1
significant                     1
occur                           1
rather                          1
occurs                          1
examples                        1
far                             1
hasnt                           1
made                            1
restarted                       1
green_light                     1
task_pausable_loop              1
green_lightis_set               1
green_lightwait                 1
threadingthreadtargettask_pausable_loopstart  1
green_lightset                  1
timesleep2                      1
green_lightclear                1
canceled                        1
killed                          1
yielding                        1
unless                          1
platformspecific                1
few                             1
approaches                      1
exercising                      1
interrupted                     1
stopped                         1
exits                           1
threadingthreadtargetfoodaemontruestart  1
sysexit                         1
upgrade                         1
multiprocesingprocesstargettask_noninterruptible  1
escape                          1
law                             1
accept                          1
responsibility                  1
moment                          1
prockill                        1
shared                          1
having                          1
lock                            1
causing                         1
deadlock                        1
multiprocessingprocesstargettask_interruptible_loop  1
keeping                         1
track                           1
processes                       1
logargs                         1
osgetpid                        1
threadingget_ident              1
idasyncioget_running_loop       1
fpid                            1
ftid                            1
flid                            1
args                            1
loghello                        1
world                           1
executor                        1
fn                              1
asynciorunfn                    1
popen                           1
interact                        1
collect                         1
combine                         1
subprocesses                    1
threadpoolexecutor              1
functions                       1
communicating                   1
sempahore                       1
queuequeue                      1
am                              1
monitors                        1
connection                      1
tips                            1
tricks                          1
openthreadingpy                 1
w                               1
fwriteinspectgetsourcethreading  1
threadingpy                     1
subset                          1
javas                           1
_os                             1
sys                             1
_sys                            1
_contextvars                    1
monotonic                       1
_time                           1
_weakrefset                     1
weakset                         1
itertools                       1
count                           1
_count                          1
_collections                    1
importerror                     1
collections                     1
regarding                       1
inherited                       1
camelcase                       1
language                        1
original                        1
imminent                        1
danger                          1
py3kso                          1
provides                        1
alias                           1
facilitates                     1
substitution                    1
multiprocessing                 1
provide                         1
compiled                        1
traceback                       1
most                            1
recent                          1
last                            1
pythoninput39                   1
1                               1
1155                            1
getsource                       1
getsourcelinesobject            1
1137                            1
getsourcelines                  1
findsourceobject                1
957                             1
findsource                      1
getsourcefileobject             1
861                             1
getsourcefile                   1
getfileobject                   1
822                             1
getfile                         1
typeerrorr                      1
moduleformatobject              1
typeerror                       1
design                          1
condition                       1
communicate                     1
conditions                      1
somehow                         1
holds                           1
communication                   1
parentschilds                   1
shuts                           1
queueshutdown                   1
timing                          1
tracking                        1
duration                        1
resource                        1
cleanup                         1
completion                      1
interrupts                      1
across                          1
childrens                       1
__str__self                     1
representation                  1
complete                        1
set_stdout                      1
set_stderr                      1
poll                            1
returns                         1
executing                       1
ask                             1
ai                              1
suggestion                      1
add_precedence                  1
ordering                        1
constraint                      1
proceed                         1
lefttoright                     1
diminishing                     1
stuff                           1
edgecases                       1
cycles                          1
depend                          1
gotchas                         1
literature                      1
runtime                         1
valid                           1
requirements                    1
dependent                       1
publish                         1
string                          1
selfname                        1
notimplementederror             1
subclasses                      1
selfthread                      1
threadingthreadtargetselftargetargskwargs  1
sleeptasktask                   1
selfsleep_for                   1
sleep_fors                      1
simpler                         1
things                          1
taskrun                         1
taskwait                        1
tasksgroup                      1
2s                              1
task3                           1
task4                           1
task5                           1
task6                           1
groupadd_start_tasktask1        1
task3depends_ontask2            1
task4depends_ontask3            1
task5depends_ontask4            1
task6depends_ontask5            1
groupset_stdoutsysstdout        1
groupset_stderrsysstderr        1
printgroupstdout                1
printgroupstderr                1
expressed                       1
actually                        1
modern                          1
express                         1
sort                            1
algorithm                       1
evaluate                        1
enforce                         1
around                          1
guess                           1
quite                           1
userdefined                     1
reused                          1
overlayimagetaskname            1
base_image                      1
qemutask                        1
overlayimagetaskoverlay_image   1
expression                      1
ssh_readyafterport_ready        1
port_readybeforessh_ready       1
run_onceadd_taskvm              1
matter                          1
run_onceadd_taskoverlay_image   1
printrun_once                   1
prints                          1
run_oncestart                   1
run_oncewait                    1
determined                      1
statements                      1
run_onceadd_taskport_ready      1
run_onceadd_taskssh_ready       1
annotated                       1
kwarg                           1
sleeptask                       1
signatures                      1
sig                             1
inspectsignaturetask__init__    1
sigparameters                   1
httpsdocspythonorg3libraryinspecthtmlinspectparameter  1
printfparameter                 1
pname                           1
pkind                           1
annotation                      1
pannotation                     1
publishes                       1
qemutasktask                    1
task__annotations__             1
inject                          1
__init__image                   1
selfimage                       1
annotations                     1
variable                        1
placed                          1
qemuvmtasktask                  1
int                             1
portreadytasktask               1
datadependencyqemuvmtaskssh_port  1
yeah                            1
weird                           1
because                         1
binding                         1
hmmm                            1
wrong                           1
twotaskport                     1
httpstypingpythonorgenlatestspecprotocolhtml  1
add_task                        1
run_onceadd_taskoverlayimagetaskbase_image  1
run_onceadd_taskqemuvmtask      1
run_onceadd_taskportreadytask   1
best                            1
overlayimagetaskbase_image      1
qemuvmtaskimage                 1
taskgroupdependencyoverlay_image  1
calculate                       1
every                           1
add                             1
allow                           1
adding                          1
evaluated                       1
considered                      1
run_onceadd_tasksimage_task     1
injection                       1
passing                         1
contrast                        1
liberal                         1
theres                          1
convenience                     1
coherence                       1
persuades                       1
fixture                         1
computations                    1
cached                          1
orders                          1
influenced                      1
left                            1
implicit                        1
reordering                      1
changing                        1
parameters                      1
list                            1
self                            1
vars                            1
selftask                        1
selfvar                         1
add_precedenceself              1
selfprecedencesappendtasks      1
add_tasksself                   1
selftasksextendtasks            1
selfidentify_data_dependencytask  1
identify_data_dependencyself    1
val                             1
varstask                        1
isinstanceval                   1
valtask                         1
return                          1
exceptiondata                   1
relies                          1
construct                       1
preserved                       1
corresponding                   1
likely                          1
candidate                       1
graphs                          1
match                           1
narrow                          1
minimal                         1
maximizes                       1
concurrency                     1
average                         1
shortest                        1
developed                       1
expressing                      1
determine                       1
algorithms                      1
develop                         1
networkx                        1
parts                           1
makes                           1
life                            1
httpsnetworkxorgdocumentationstablereferenceintroductionhtml  1
broken                          1
printed                         1
renders                         1
colorstext                      1
outlining                       1
issue                           1
td                              1
astart                          1
bis                             1
cgreat                          1
ddebug                          1
20251119                        1
today                           1
configuring                     1
implementation                  1
machines                        1
come                            1
installed                       1
skip                            1
desktop                         1
installation                    1
perfect                         1
developing                      1
download                        1
httpscloudimagesubuntucom       1
noble                           1
select                          1
arm64                           1
fssl                            1
httpscloudimagesubuntucomnoblecurrentnobleservercloudimgarm64img  1
noticed                         1
hangs                           1
started                         1
systemdtimedatedservice         1
job                             1
systemdnetworkdwaitonlineservicestart  1
bootstrap                       1
style                           1
declaratively                   1
configures                      1
templating                      1
built                           1
keyvalues                       1
json                            1
interpolated                    1
jinjatemplated                  1
complex                         1
nor                             1
variations                      1
template                        1
httpscloudinitreadthedocsioenlatestexplanationinstancedatahtmlinstancedata  1
mentioning                      1
usually                         1
fetched                         1
cloudproviders                  1
onplatform                      1
since                           1
locally                         1
faasvmtestrunner                1
matches                         1
varlibclouddatainstanceid       1
skips                           1
turn                            1
supports                        1
distinguish                     1
cloudinits                      1
parser                          1
httpscloudinitreadthedocsioenlatestreferencemoduleshtml  1
httpscloudinitreadthedocsioenlatestexplanationformathtmluserdataformats  1
httpscloudinitreadthedocsioenlatestexplanationaboutcloudconfightml  1
hostname                        1
package_update                  1
package_upgrade                 1
write_files                     1
content                         1
binbash                         1
euo                             1
pipefail                        1
export                          1
debian_frontendnoninteractive   1
noinstallrecommends             1
cacertificates                  1
git                             1
opensshclient                   1
python3                         1
python3pip                      1
python3venv                     1
lssf                            1
httpsastralshuvinstallsh        1
g                               1
rootlocalbinuv                  1
usrlocalbinuv                   1
runcmd                          1
rm                              1
mode                            1
faas_user                       1
allroot                         1
nopasswd                        1
sbinpoweroff                    1
package                         1
manager                         1
id                              1
couple                          1
finished                        1
reboot                          1
want                            1
immediately                     1
signaling                       1
opportunity                     1
discussed                       1
policy                          1
avoid                           1
membership                      1
ability                         1
provoke                         1
password                        1
prompt                          1
_passwordless_                  1
keypair                         1
connect                         1
separately                      1
created                         1
touched                         1
later                           1
mentioned                       1
earlier                         1
great                           1
interpolate                     1
keys                            1
sometimes                       1
messy                           1
httpscloudinitreadthedocsioenlatestreferencemoduleshtmlpowerstatechange  1
power                           1
change                          1
httpscloudinitreadthedocsioenlatestreferencemoduleshtmlusersandgroups  1
groups                          1
httpswwwsudowsdocsmansudoersman  1
manual                          1
stands                          1
reserved                        1
ahead                           1
allocated                       1
observe                         1
examing                         1
620102144                       1
resize                          1
20g                             1
canonicals                      1
distribution                    1
ondisk                          1
total                           1
qcow                            1
v1                              1
snapshot                        1
qcow3                           1
optional                        1
encryption                      1
improved                        1
clustering                      1
snapshots                       1
weve                            1
given                           1
permission                      1
consume                         1
least                           1
20gib                           1
enough                          1
question                        1
cleanliness                     1
precisely                       1
organization                    1
reproducibility                 1
sideeffects                     1
cases                           1
errors                          1
normal                          1
development                     1
changed                         1
operate                         1
faasd                           1
changes                         1
route                           1
connections                     1
containers                      1
underlying                      1
nondeterminism                  1
falsepositives                  1
falsenegatives                  1
flaky                           1
address                         1
goal                            1
build                           1
assertions                      1
top                             1
foundation                      1
verify                          1
program                         1
solution                        1
clean                           1
voilà                           1
fresh                           1
however                         1
revisiting                      1
distinction                     1
copying                         1
usage                           1
double                          1
1gib                            1
pay                             1
iops                            1
looking                         1
closely                         1
us                              1
clue                            1
didnt                           1
whole                           1
against                         1
spacesaving                     1
often                           1
clearly                         1
defined                         1
differences                     1
httpswwwqemuorgdocsmasterinteropqcow2html  1
815                             1
describe                        1
offset                          1
1619                            1
theoretical                     1
32bit                           1
integer                         1
corresponds                     1
billion                         1
character                       1
1023                            1
characters                      1
heres                           1
testimg                         1
192                             1
197120                          1
extra                           1
values                          1
relative                        1
practically                     1
dramatically                    1
lower                           1
196kib                          1
3000x                           1
smaller                         1
naive                           1
comes                           1
tradeoff                        1
rename                          1
mv                              1
fooimg                          1
virthighmemon                   1
4096                            1
usermodelvirtionetpci           1
anytime                         1
accessible                      1
apply                           1
projects                        1
reuse                           1
discard                         1
described                       1
above                           1
applied                         1
bootup                          1
strategy                        1
inside                          1
separate                        1
second                          1
perform                         1
leaving                         1
typically                       1
contains                        1
static                          1
written                         1
convenient                      1
mostly                          1
permutations                    1
options                         1
filesystem                      1
choice                          1
specifying                      1
remote                          1
provider                        1
defaults                        1
focus                           1
core                            1
functionality                   1
temporary                       1
copies                          1
specified                       1
array                           1
tmp_diruserdata                 1
tmp_dirmetadata                 1
boottime                        1
enumerates                      1
devices                         1
checks                          1
starting                        1
sectors                         1
fixed                           1
segments                        1
compatibility                   1
reasons                         1
thirty                          1
strictly                        1
necessary                       1
usecase                         1
nothing                         1
lost                            1
ridge                           1
interchange                     1
named                           1
town                            1
httpsenwikipediaorgwikiblazing_saddles  1
wikipedia                       1
explained                       1
works                           1
linux                           1
container                       1
mounts                          1
nonexistent                     1
directories                     1
empty                           1
force                           1
seedisoseediso                  1
userdatauserdata                1
metadatametadata                1
ubuntulatest                    1
echo                            1
sshkeypub                       1
qq                              1
cloudimageutils                 1
notice                          1
quickandeasy                    1
injecting                       1
ascii                           1
text                            1
hexdump                         1
s                               1
162048                          1
n                               1
256                             1
00008000                        1
43                              1
44                              1
31                              1
4c                              1
49                              1
4e                              1
55                              1
58                              1
cd001linux                      1
00008010                        1
00008020                        1
63                              1
69                              1
64                              1
74                              1
00008030                        1
00008040                        1
00008050                        1
00008060                        1
00008070                        1
00008080                        1
14                              1
00008090                        1
22                              1
000080a0                        1
46                              1
000080b0                        1
02                              1
000080c0                        1
00008100                        1
present                         1
identify                        1
httpsmanpagesdebianorgtestingcloudimageutilscloudlocalds1enhtml  1
debian                          1
manpages                        1
httpsdocumentationubuntucompublicimagespublicimageshowtouselocalcloudinitds  1
datasource                      1
httpsgithubcomcanonicalcloudutils  1
github                          1
canonicalcloudutils             1
operating                       1
produce                         1
hard                            1
thing                           1
break                           1
linebyline                      1
64bit                           1
simulator                       1
processor                       1
selecting                       1
chance                          1
nearnative                      1
translate                       1
coming                          1
proper                          1
causes                          1
hardwarebased                   1
virtualization                  1
much                            1
faster                          1
softwarebased                   1
exposes                         1
isa                             1
optimized                       1
mind                            1
indicates                       1
generic                         1
whose                           1
emulated                        1
limit                           1
possible                        1
chosen                          1
raspberrypis                    1
exactly                         1
highmemon                       1
grant                           1
expanding                       1
addressspace                    1
cores                           1
gibibytes                       1
drives                          1
frontend                        1
presented                       1
expose                          1
virtioblkpci                    1
virtio                          1
highperformance                 1
paravirtualized                 1
informs                         1
drivers                         1
virtualized                     1
tools                           1
cooperate                       1
grow                            1
experimentation                 1
usermode                        1
internally                      1
nat                             1
overhead                        1
intercept                       1
packets                         1
rewrite                         1
headers                         1
routing                         1
table                           1
userspace                       1
wanted                          1
improve                         1
tapbridge                       1
limited                         1
tap                             1
ethernet                        1
bridge                          1
layer                           1
switch                          1
hosts                           1
area                            1
httpsdeveloperapplecomdocumentationhypervisor  1
apple                           1
documentation                   1
getting                         1
shorthand                       1
graphical                       1
multiplexes                     1
interfaces                      1
stdinstdout                     1
armspecific                     1
bundled                         1
homebrew                        1
firmware                        1
care                            1
wouldnt                         1
logs                            1
shutting                        1
qemulogtxt                      1
noshutdown                      1
enable                          1
unixqemumonitorsock             1
nc                              1
u                               1
qemumonitorsock                 1
status                          1
current                         1
behalf                          1
customers                       1
access                          1
providers                       1
monitoring                      1
behavior                        1
reliability                     1
driving                         1
ones                            1
easy                            1
ifvirtioformatqcow2filetest_runnerimg  1
usermodelvirtionetpcihostfwdtcp222222  1
devnull                         1
background                      1
home                            1
qa                              1
pyprojecttoml                   1
pytesttoml                      1
uvlock                          1
src                             1
exclude                         1
sshssh                          1
stricthostkeycheckingno         1
userknownhostsfiledevnull       1
connecttimeout1                 1
connectionattempts1             1
loglevelquiet                   1
2222                            1
sshkey                          1
readinessdone                   1
0m0120s                         1
availabilitydone                1
0m11687s                        1
pytestdone                      1
0m2946s                         1
```

Lots random data like dates and numbers, or programming syntax. 

We could trim these unknown values by filtering against a dictionary of
indexable words. And do stemming, etc. to coalesce distinct but related words.

I think the goal should be use natural language processing libraries in python
to build a search index that is then compressed and translated to a javascript
module that my blog front-end can consume.

I can measure improvements to search index quality and compression ratio
against a wikipedia dump or something. Or a scrape of popular tech blogs I
like.
