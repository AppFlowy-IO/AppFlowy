import { Observable, Subject } from 'rxjs';

export class ChangeNotifier<T> {
  private isUnsubscribe = false;
  private subject = new Subject<T>();

  notify(value: T) {
    this.subject.next(value);
  }

  get observer(): Observable<T> | null {
    if (this.isUnsubscribe) {
      return null;
    }

    return this.subject.asObservable();
  }

  // Unsubscribe the subject might cause [UnsubscribedError] error if there is
  // ongoing Observable execution.
  //
  // Maybe you should use the [Subscription] that returned when call subscribe on
  // [Observable] to unsubscribe.
  unsubscribe = () => {
    if (!this.isUnsubscribe) {
      this.isUnsubscribe = true;
      this.subject.unsubscribe();
    }
  };
}
