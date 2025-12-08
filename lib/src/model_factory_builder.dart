import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'model_factory_generator.dart';

Builder modelFactoryBuilder(BuilderOptions options) =>
    PartBuilder([ModelFactoryGenerator()], '.factory.g.dart');
