import csv

template = """
[gd_resource type="Resource" script_class="Element" load_steps=2 format=3 uid="uid://b1mtqdm7fvk7b"]

[ext_resource type="Script" path="res://scripts/resources/element.gd" id="1_kcefu"]

[resource]
script = ExtResource("1_kcefu")
name = "<$1>"
atomic_number = <$2>
symbol = "<$3>"
natural = <$4>
has_temp_data = <$5>
melting_point = <$6>
boiling_point = <$7>
category = <$8>
"""

catstring_table = { "Nonmetal": 0,
                    "Noble Gas": 1,
                    "Alkali Metal": 2,
                    "Alkaline Earth Metal": 3,
                    "Halogen": 4,
                    "Metal": 5,
                    "Metalloid": 6,
                    "Transition Metal": 7,
                    "Lanthanide": 8,
                    "Actinide": 9,
                    "Transactinide": 10,
                    "": 11
    }

with open('periodic_table_of_elements.csv', newline='') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=',')
    for row in spamreader:
        if not row[0] == "AtomicNumber":
            atomic_number = row[0].strip()
            name = row[1].strip()
            symbol = row[2].strip()
            natural = row[11]
            melting_point = row[20] if row[20] != "" else "0.0"
            boiling_point = row[21] if row[21] != "" else "0.0"
            has_temp_data = "true" if melting_point != "" or boiling_point != "" else "false"
            cat = str(catstring_table[row[15]])
            t = template.replace("<$1>", name).replace("<$2>", atomic_number).replace("<$3>", symbol).replace("<$4>", "true" if natural == "yes" else "false").replace("<$5>", has_temp_data).replace("<$6>", melting_point).replace("<$7>", boiling_point).replace("<$8>", cat)
            print(t)
            f = open(name + ".tres", "w")
            f.write(t)
            f.close()
