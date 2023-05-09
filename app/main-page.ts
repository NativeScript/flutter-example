import { EventData, Page } from "@nativescript/core";
import { HelloWorldModel } from "./main-view-model";

let vm: HelloWorldModel;

export function navigatingTo(args: EventData) {
  const page = <Page>args.object;
  page.actionBarHidden = true;
  vm = new HelloWorldModel();
  page.bindingContext = vm;
}

export function loadedFlutter(args) {
  vm.flutter = args.object;
}
