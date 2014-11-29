BEGIN{
    FS="#"
}
/Sink #[0-9]+/{
    type = "sink"
    id=$2
    FS = ":"
}
/Source #[0-9]+/{
type = "source"
id=$2
FS = ":"
}
/Description/{
    FS = " ";
    desc=$2
}
/Base Volume/{ FS="#"; print type ";" id ";" $5 ";" desc}

END{}