# Sets sound of all audio outputs to 0
# (or at least that is what i am hoping it's going to do)

for i in $(pactl list sinks short | awk '{ print $1;}')
do
    pactl set-sink-volume $i 0%
done
